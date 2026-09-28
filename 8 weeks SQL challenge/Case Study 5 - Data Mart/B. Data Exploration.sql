SELECT *
FROM clean_weekly_sales

------------------------B. Data Exploration------------------------

/*1.  What day of the week is used for each week_date value?*/

SELECT DISTINCT TO_CHAR(week_date, 'Day') AS day_of_week
FROM clean_weekly_sales;

/*2.  What range of week numbers are missing from the dataset?*/

SELECT MIN(week_number) AS minimum_week_number,
       MAX(week_number) AS maximum_week_number
FROM clean_weekly_sales;
----OUTPUT: 13 and 36, so 1-12 week number is missing and 37-52 week numbers missing

/*3.  How many total transactions were there for each year in the dataset?*/

SELECT calendar_year,
       SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;

/*4.  What is the total sales for each region for each month?*/

SELECT region,
       month_number,
       SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;

/*5.  What is the total count of transactions for each platform*/

SELECT platform,
       SUM(transactions) AS transactions_count
FROM clean_weekly_sales
GROUP BY platform
ORDER BY platform;

/*6.  What is the percentage of sales for Retail vs Shopify for each month?*/

SELECT calendar_year,
     month_number,
     CONCAT(
       ROUND(
         100.0 * SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) / SUM(sales),
         2
       ),
       '%'
     ) AS retail_percentage,
     CONCAT(
       ROUND(
         100.0 * SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) / SUM(sales),
         2
       ),
       '%'
     ) AS shopify_percentage
FROM clean_weekly_sales
GROUP BY calendar_year, month_number
ORDER BY calendar_year, month_number;

/*7.  What is the percentage of sales by demographic for each year in the dataset?*/

WITH cte AS (
    SELECT calendar_year,
           demographic,
           SUM(sales) AS total_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year, demographic
)
SELECT calendar_year,
       demographic,
       total_sales,
       CONCAT(
           ROUND(100.0 * total_sales / SUM(total_sales) OVER (PARTITION BY calendar_year), 2),
           '%'
       ) AS sales_percent
FROM cte
ORDER BY calendar_year, sales_percent DESC;

--OR

SELECT calendar_year,
     CONCAT(
       ROUND(100.0 * SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END) / SUM(sales), 2),
       '%'
     ) AS families_percentage,
     CONCAT(
       ROUND(100.0 * SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END) / SUM(sales), 2),
       '%'
     ) AS couples_percentage,
     CONCAT(
       ROUND(100.0 * SUM(CASE WHEN demographic = 'Unkown' THEN sales ELSE 0 END) / SUM(sales), 2),
       '%'
     ) AS unkown_percentage
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;

/*8.  Which age_band and demographic values contribute the most to Retail sales?*/

SELECT age_band,
     demographic,
     CONCAT(
       ROUND(
         100.0 * SUM(sales) /
         (SELECT SUM(sales) FROM clean_weekly_sales WHERE platform = 'Retail'),
         2
       ),
       '%'
     ) AS contribution
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY SUM(sales) DESC;

/*9.  Can we use the avg_transaction column to find the average transaction size for each year for 
Retail vs Shopify? If not - how would you calculate it instead?*/

SELECT calendar_year,
       platform,
       ROUND(AVG(avg_transaction), 2) AS wrong_avg_size,
       ROUND(SUM(sales)::NUMERIC / SUM(transactions)::NUMERIC, 2) AS correct_avg_size
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year;