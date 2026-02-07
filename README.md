![GitHub stars](https://img.shields.io/github/stars/Prathamesh-14-a/customer-segmentation-rfm)
![GitHub license](https://img.shields.io/github/license/Prathamesh-14-a/customer-segmentation-rfm)
# Customer Segmentation using RFM Analysis

## Overview
This project performs customer segmentation using RFM (Recency, Frequency, Monetary) analysis to identify high-value customers and behavioral patterns for targeted marketing.

## How to View the Project
- Open the PDF in `/report/`
- Run the Python notebook in `/notebooks/`
- Execute SQL script in your SQL Server
- Open the Power BI dashboard from `/powerbi/`

## Tools Used
- Python (Pandas, NumPy)
- SQL Server
- Power BI

## Dataset
- Source: UCI Machine Learning Repository - Online Retail Dataset
- Dataset Link:  https://uci-ics-mlr-prod.aws.uci.edu/dataset/352/online%2Bretail?utm_source=chatgpt.com 
- Time Period: Dec 2010 – Dec 2011
- Data cleaned to remove cancellations, invalid transactions, and null customers

## Methodology
1. Data cleaning and preprocessing in Python
2. RFM metric calculation using SQL
3. Quantile-based RFM scoring (1–5)
4. Customer segmentation using business rules
5. Interactive dashboard development in Power BI

## Dashboard
Power BI dashboard includes:
- Executive overview of customer segments
- Revenue contribution by segment
- Behavioral analysis of Recency, Frequency, and Monetary metrics

## Files in this Repository
- `/notebooks` – Data cleaning notebook
- `/sql` – SQL scripts for RFM aggregation and scoring
- `/powerbi` – Power BI dashboard file
- `/report` – Project report (PDF)

## Results
Champions and Loyal customers contribute the majority of revenue, while a significant portion of customers fall into At-Risk and Lost segments, indicating reactivation opportunities.

## Author
Prathmesh Ambulge  
GitHub: https://github.com/Prathamesh-14-a


If you find this project useful, feel free to ⭐ the repo!

