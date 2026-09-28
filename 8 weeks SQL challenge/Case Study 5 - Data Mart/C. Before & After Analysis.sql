SELECT *
FROM clean_weekly_sales

------------------------C. Before & After Analysis------------------------

/*This technique is usually used when we inspect an important event and want to inspect the impact 
before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging
changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and 
the previous week_date values would be before

Using this analysis approach - answer the following questions:*/

SELECT DISTINCT week_number
FROM clean_weekly_sales
WHERE week_date = '2020-06-15';
--OUTPUT: 25

/*1.  What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or 
reduction rate in actual values and percentage of sales?*/
WITH cte AS (
    SELECT SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
)
SELECT before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte;

/*2.  What about the entire 12 weeks before and after?*/

WITH cte AS (
    SELECT SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
)
SELECT before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte;

/*3.  How do the sale metrics for these 2 periods before and after compare with the previous years 
in 2018 and 2019?*/

--For 4 weeks before and after compare with the previous years in 2018 and 2019?
WITH cte AS (
    SELECT calendar_year,
           SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year
)
SELECT calendar_year,
       before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte;

--For 12 weeks before and after compare with the previous years in 2018 and 2019?
WITH cte AS (
    SELECT calendar_year,
           SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year
)
SELECT calendar_year,
       before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte;