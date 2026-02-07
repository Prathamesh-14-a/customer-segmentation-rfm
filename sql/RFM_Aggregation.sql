
--Creating New Database To Import Cleaned Dataset Into 
-- “This is for local analysis only.”
CREATE DATABASE CustomerAnalytics;
USE CustomerAnalytics;

-- We Have Imported our cleaned data 

SELECT * FROM dbo.clean_online_retail;

-- Python final data rows == imported data
-- Nothing Fails while importing data

---------------------------------------------------------------------------------------
-- STEP 1: Define fixed analysis date for reproducible RFM calculation

DECLARE @analysis_date DATE;

SELECT @analysis_date = DATEADD(DAY, 1, MAX(InvoiceDate))
FROM dbo.clean_online_retail;



-- STEP 2: Aggregate transactions at customer level
-- We calculate last purchase date, frequency, and monetary value
DROP TABLE IF EXISTS dbo.rfm_base;
SELECT
    CustomerID ,
    DATEDIFF(
        DAY,
        MAX(InvoiceDate),
        @analysis_date
    ) AS Recency,
    
    COUNT(DISTINCT InvoiceNo) AS frequency ,
    
    SUM(TotalAmount) as monetary_value

INTO dbo.rfm_base
FROM dbo.clean_online_retail
GROUP BY CustomerID;

--------------------------------------------------------------------------------------------
--Step3
--Validating Recency , Frequency , Monetary_Values not fails
--Check Recency >= 0
SELECT * 
FROM dbo.rfm_base
WHERE Recency <= 0;  -- 0 Rows Returned

--Check Frequency >= 1
SELECT * 
FROM dbo.rfm_base
WHERE frequency < 1;  -- 0 Rows Returned

--Check Monetary > 0
SELECT * 
FROM dbo.rfm_base
WHERE monetary_value < 0; -- 0 Rows Returned

--Distribution sanity
SELECT
    MIN(Recency)    AS min_recency,
    MAX(Recency)    AS max_recency,
    AVG(Recency)    AS avg_recency,

    MIN(frequency) AS min_frequency,
    MAX(frequency) AS max_frequency,
    AVG(frequency) AS avg_frequency,

    MIN(monetary_value)  AS min_monetary,
    MAX(monetary_value)  AS max_monetary,
    AVG(monetary_value)  AS avg_monetary
FROM dbo.rfm_base;

SELECT COUNT(DISTINCT CustomerID)
FROM dbo.rfm_base;

-- RFM Validation Summary:
-- Recency: No negative values found
-- Frequency: Minimum value = 1
-- Monetary: All values > 0
-- CustomerID: No duplicates
-- Distributions checked and found reasonable

------------------------------------------------------------------------------------------

--STEP 4
--Write CTE Query for Calculate Recency , Frequency ,Monetary Buckets and Scoring with segmentation
DROP TABLE IF EXISTS dbo.rfm_scored;

WITH RFM_Bucket AS(
   SELECT 
          CustomerID , 
          Recency , 
          frequency ,
          monetary_value ,
          NTILE(5) 
                  OVER (ORDER BY Recency) AS Recency_Bucket , 
          NTILE(5) 
                  OVER (ORDER BY frequency DESC) AS Frequency_Bucket , 
          NTILE(5)
                 OVER(ORDER BY monetary_value DESC) AS Monetary_Bucket 
   FROM dbo.rfm_base 
), 
RFM_Scores AS(
SELECT 
       CustomerID , 
       Recency_Bucket ,
       Frequency_Bucket ,
       Monetary_Bucket ,
       -- Calculate R_Score , F_Score , M_Score using thw output of above CTE
      CASE
           WHEN Recency_Bucket = 1 THEN 5 
           WHEN Recency_Bucket = 2 THEN 4 
           WHEN Recency_Bucket = 3 THEN 3 
           WHEN Recency_Bucket = 4 THEN 2 
           WHEN Recency_Bucket = 5 THEN 1
           ELSE 1
        END AS R_Score ,  

      CASE
          WHEN Frequency_Bucket = 1 THEN 5
          WHEN Frequency_Bucket = 2 THEN 4
          WHEN Frequency_Bucket = 3 THEN 3
          WHEN Frequency_Bucket = 4 THEN 2
          WHEN Frequency_Bucket = 5 THEN 1
          ELSE 1
      END AS F_Score ,

      CASE 
          WHEN Monetary_Bucket = 1 THEN 5
          WHEN Monetary_Bucket = 2 THEN 4
          WHEN Monetary_Bucket = 3 THEN 3
          WHEN Monetary_Bucket = 4 THEN 2
          WHEN Monetary_Bucket = 5 THEN 1
          ELSE 1
      END AS M_Score 
FROM RFM_Bucket 
)
SELECT * ,
    -- Getting RFM_Score
    CONCAT(R_Score , F_Score , M_Score ) AS RFM_Score , 

    --Segmenting Based on Scores
    CASE 
       -- 1.'Champions' : For Best Customers
       WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score  >= 4
               THEN 'Champions'  
               
       -- 2. 'Loyal' : For Repeat Buyers
       WHEN R_Score >= 3 AND F_Score >= 4 AND M_Score >= 3
               THEN 'Loyal'              

      -- 3. 'Potential Loyalists': For Them Who Could Become Loyal
       WHEN R_Score >= 4 AND F_Score BETWEEN 2 AND 3 AND M_Score BETWEEN 2 AND 3
               THEN 'Potential Loyalists' 
     
      -- 4. 'New Customers' :  For Recently Acquired Customers
       WHEN R_Score = 5 AND F_Score <= 2 AND M_Score <= 2
               THEN 'New Customers'      

      -- 5 . 'At Risk' : For Who Slipping Away
       WHEN R_Score <= 2 AND F_Score >= 3 AND M_Score >= 3
               THEN 'At Risk'            
      
      -- 6 . 'Lost Big Spenders' : For Them Who Were High Valued But Inactive
       WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score >= 4
               THEN 'Lost Big Spenders'  
      
      -- 7 . 'LOST' : For Churned Customers
       WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score <= 2
               THEN 'LOST' 
       
       ELSE 
           'Others'

    END AS Segment_Name
INTO
    dbo.rfm_scored
FROM 
    RFM_Scores;

----------------------------------------------------------------------------------------------

SELECT * FROM dbo.rfm_scored;
-- STEP 5
-- Checking All Segments With Counts
--Validate segment size and value contribution.
SELECT 
      Segment_Name , 
      COUNT(CustomerID) AS No_Of_Customers
FROM rfm_scored
GROUP BY Segment_Name
ORDER BY No_Of_Customers DESC;

-- At Risk — 542 = “We have a large base of previously valuable customers going inactive.”
-- New Customers — 53 = “The dataset spans a long historical window, so truly new customers
                       --near the reference date are limited.”
-- Lost Big Spenders — 47 = “Although small, this segment represents disproportionately high revenue risk.”
-- Others — 1105 = “Others are customers with inconsistent or transitional behavior.”

----------------------------------------------------------------------------------------

--STEP 6
--Creating one final rfm_final table 
DROP TABLE IF EXISTS dbo.rfm_final;
SELECT 
     A.CustomerID , 
     A.Recency  ,
     A.frequency AS Frequency , 
     A.monetary_value AS Monetary ,
     B.R_Score , 
     B.F_Score ,
     B.M_Score , 
     B.RFM_Score ,
     B.Segment_Name
INTO 
    dbo.rfm_final
FROM 
    dbo.rfm_base  AS A
JOIN
    dbo.rfm_scored AS B
ON 
  A.CustomerID = B.CustomerID;

  SELECT * FROM rfm_final;
---------------------------------------------------------------------------------

--STEP 7: VALIDATION
--Revenue Per Segment
SELECT
    Segment_Name,
    SUM(Monetary) AS total_revenue
FROM dbo.rfm_final
GROUP BY Segment_Name
ORDER BY total_revenue DESC;


--Average R / F / M per segment
SELECT
    Segment_Name,
    AVG(Recency)   AS avg_recency,
    AVG(Frequency) AS avg_frequency,
    AVG(Monetary)  AS avg_monetary
FROM dbo.rfm_final
GROUP BY Segment_Name
ORDER BY Segment_Name;

-- Revenue share %
SELECT
    Segment_Name,
    SUM(Monetary) AS total_revenue,
    SUM(Monetary) * 100.0 / SUM(SUM(Monetary)) OVER () AS revenue_pct
FROM dbo.rfm_final
GROUP BY Segment_Name
ORDER BY total_revenue DESC;
-- More than 60% Revenue Is From Champions Segment





  
