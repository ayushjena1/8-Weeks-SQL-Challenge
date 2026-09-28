ALTER USER postgres SET search_path TO data_mart, public;
SET search_path = data_mart;

SELECT * FROM weekly_sales

------------------------A. Data Cleansing Steps------------------------

/*In a single query, perform the following operations and generate a new table in the data_mart 
schema named clean_weekly_sales:
1.  Convert the week_date to a DATE format
2.  Add a week_number as the second column for each week_date value, for example any value from 
    the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
3.  Add a month_number with the calendar month for each week_date value as the 3rd column
4.  Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
5.  Add a new column called age_band after the original segment column using the following mapping 
    on the number inside the segment value
        segment	  age_band
        1	      Young Adults
        2	      Middle Aged
        3 or 4	  Retirees

6.  Add a new demographic column using the following mapping for the first letter in the segment values:
        segment	  demographic
        C	      Couples
        F	      Families

7.  Ensure all null string values with an "unknown" string value in the original segment column as 
    well as the new age_band and demographic columns
8.  Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 
    decimal places for each record*/

DROP TABLE IF EXISTS clean_weekly_sales;

CREATE TABLE clean_weekly_sales AS
SELECT
  -- Converting to date format
  TO_DATE(week_date, 'DD/MM/YY') AS week_date,
  
  -- Extracting week number, month number, and year
  EXTRACT(WEEK FROM TO_DATE(week_date, 'DD/MM/YY'))::INT AS week_number,
  EXTRACT(MONTH FROM TO_DATE(week_date, 'DD/MM/YY'))::INT AS month_number,
  EXTRACT(YEAR FROM TO_DATE(week_date, 'DD/MM/YY'))::INT AS calendar_year,
  
  region,
  platform,
  
  -- Handling NULLs
  CASE 
    WHEN segment = 'null' OR segment IS NULL THEN 'Unknown'
    ELSE segment 
  END AS segment,
  
  -- Extracting demographic age from segment (first character)
  CASE 
    WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
    WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
    WHEN RIGHT(segment, 1) IN ('3', '4') THEN 'Retirees'
    ELSE 'Unknown'
  END AS age_band,
  
  -- Extracting demographic type from segment (second character)
  CASE 
    WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
    WHEN LEFT(segment, 1) = 'F' THEN 'Families'
    ELSE 'Unknown'
  END AS demographic,
  
  customer_type,
  transactions,
  sales,
  
  -- Getting average sales 
  ROUND(sales::NUMERIC / transactions, 2) AS avg_transaction
FROM data_mart.weekly_sales;