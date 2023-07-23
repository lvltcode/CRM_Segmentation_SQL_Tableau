WITH 

CRM_Score as (
    SELECT 
        Member_Account_Code,
        ROUND(SUM(Sales_amt) / 23657,2) as Revenue_usd,
        COUNT(DISTINCT Invoice) as Invoice_num,
        CASE
            -- 1USD = 23657 VND on July 2023
            WHEN (SUM(Sales_amt) / 23657) > 50000 THEN 'PLATINUM'
            WHEN (SUM(Sales_amt) / 23657) <=50000 AND (SUM(Sales_amt) / 23657) >= 25000 THEN 'GOLD'
            WHEN (SUM(Sales_amt) / 23657) <25000 AND (SUM(Sales_amt) / 23657) >= 10000 THEN 'SILVER'
            WHEN (SUM(Sales_amt) / 23657) <10000 AND (SUM(Sales_amt) / 23657) >= 3000 THEN 'CT'
            ELSE 'OTHERS'
            END as Ranking,
        SUM(Sales_Qty) as Quantity,
        MONTH(Date) as Month_num
    FROM CRM_Analysis
    GROUP BY Member_Account_Code, Date
),

CRM_Summary as (
    SELECT * FROM (
        SELECT 
        Ranking as Segmentation,
        COUNT(DISTINCT Member_Account_Code) as Total_of_clients,
        SUM(Revenue_usd) as Total_sales,
        SUM(Invoice_num) as Total_transactions,
        SUM(Quantity) as Total_items_sold,
        ROUND(SUM(Revenue_usd) / SUM(Invoice_num),2) as ATV,
        CAST(SUM(Quantity) / SUM(Invoice_num) as float) as UTP
    FROM CRM_Score 
    GROUP BY Ranking
) t1 JOIN (SELECT Ranking, SUM(Invoice_num) as Trans_more_two
    FROM CRM_Score 
    WHERE Quantity >=2
    GROUP BY Ranking) t2
ON t1.Segmentation = t2.Ranking
),

CRM_total as (
    SELECT 'Total' as Segmentation,
        COUNT(DISTINCT Member_Account_Code) as Total_of_clients,
        SUM(Revenue_usd) as Total_sales,
        SUM(Invoice_num) as Total_transactions,
        SUM(Quantity) as Total_items_sold,
        (SELECT SUM(Invoice_num) FROM CRM_Score WHERE Quantity >= 2) as Trans_more_two,
        ROUND(SUM(Revenue_usd) / SUM(Invoice_num),2) as ATV,
        CAST(SUM(Quantity) / SUM(Invoice_num) as float) as UTP
    FROM CRM_Score CRM
)

SELECT *
FROM CRM_total
UNION 
SELECT Segmentation,
        Total_of_clients,
        Total_sales,
        Total_transactions,
        Total_items_sold,
        Trans_more_two,
        ATV,
        UTP
FROM CRM_Summary;
