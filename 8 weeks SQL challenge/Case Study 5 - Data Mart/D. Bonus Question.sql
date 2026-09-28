SELECT *
FROM clean_weekly_sales

------------------------D. Bonus Question------------------------

/*Which areas of the business have the highest negative impact in sales metrics performance in 
2020 for the 12 week before and after period?
region
platform
age_band
demographic
customer_type*/

--Region Based
WITH cte AS (
    SELECT calendar_year,
           region,
           SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY calendar_year, region
)
SELECT region,
       before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte
ORDER BY region;


--Platform Based
WITH cte AS (
    SELECT calendar_year,
           platform,
           SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY calendar_year, platform
)
SELECT platform,
       before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte
ORDER BY platform;


--Age Based
WITH cte AS (
    SELECT calendar_year,
           age_band,
           SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY calendar_year, age_band
)
SELECT age_band,
       before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte
ORDER BY age_band;


--Demographic Based
WITH cte AS (
    SELECT calendar_year,
           demographic,
           SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY calendar_year, demographic
)
SELECT demographic,
       before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte
ORDER BY demographic;


--Customer Based
WITH cte AS (
    SELECT calendar_year,
           customer_type,
           SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY calendar_year, customer_type
)
SELECT customer_type,
       before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte
ORDER BY customer_type;