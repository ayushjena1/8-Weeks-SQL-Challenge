ALTER USER postgres SET search_path TO fresh_segments, public;
SET search_path = fresh_segments;

SELECT *
FROM interest_map

SELECT *
FROM interest_metrics

------------------------A. Data Exploration and Cleansing------------------------

/*1.  Update the fresh_segments.interest_metrics table by modifying the month_year column to be a 
date data type with the start of the month*/

ALTER TABLE fresh_segments.interest_metrics
  ALTER COLUMN month_year TYPE DATE USING TO_DATE(month_year, 'MM-YYYY');

/*2.  What is count of records in the fresh_segments.interest_metrics for each month_year value 
sorted in chronological order (earliest to latest) with the null values appearing first?*/

SELECT month_year,
       COUNT(*) AS records_count
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST;

/*3.  What do you think we should do with these null values in the fresh_segments.interest_metrics*/

SELECT COUNT(*)
FROM interest_metrics
WHERE interest_id IS NULL;

--I checked across different columns most NULL's are interest_id and month_year
--Without an interest_id or a month_year, these records represent empty/corrupted logging entries
--Will remove the NULL values since question did not mentioned to replace NULL's. 
--Also it's not a coding question so you can keep the NULL's if you want. 
--Just make sure you filter them out while writing codes.

DELETE FROM fresh_segments.interest_metrics
WHERE month_year IS NULL
  OR interest_id IS NULL;

/*4.  How many interest_id values exist in the fresh_segments.interest_metrics table but not 
in the fresh_segments.interest_map table? What about the other way around?*/

--How many interest_ids exist in interest_metrics but not in interest_map?
SELECT COUNT(DISTINCT interest_id) AS metrics_not_in_map
FROM interest_metrics
WHERE interest_id::INT NOT IN (SELECT id FROM interest_map);

--How many ids exist in interest_map but not in interest_metrics?
SELECT COUNT(DISTINCT id) AS map_not_in_metrics
FROM interest_map
WHERE id NOT IN (SELECT DISTINCT interest_id::INT FROM interest_metrics);

/*5.  Summarise the id values in the fresh_segments.interest_map by its total record count in this table*/

SELECT COUNT(id) As total_ids,
       COUNT(DISTINCT id) unique_ids
FROM interest_map;

/*6.  What sort of table join should we perform for our analysis and why? Check your logic by checking 
the rows where interest_id = 21246 in your joined output and include all columns from 
interest_metrics and all columns from interest_map except from the id column.*/

SELECT me.*,
       ma.*
FROM interest_metrics AS me
LEFT JOIN interest_map AS ma ON ma.id = me.interest_id::INT
WHERE me.interest_id::INT = 21246;

/*7.  Are there any records in your joined table where the month_year value is before the created_at 
value from the fresh_segments.interest_map table? Do you think these values are valid and why?*/

SELECT COUNT(*) AS records_before_created_at
FROM interest_metrics AS me
LEFT JOIN interest_map AS ma ON me.interest_id::INT = ma.id
WHERE me.month_year < ma.created_at;

--Above output shows 188 records before created_at values. 
--It might be a case that the 188 records are values of same month in month_year. Let's check that.

SELECT me.interest_id, ma.interest_name, me.month_year, ma.created_at
FROM interest_metrics AS me
INNER JOIN interest_map AS ma
    ON me.interest_id::INT = ma.id
WHERE me.month_year < ma.created_at;

--Seems that the 188 records are values of same month, however let's cross-check
--To check again I have written another code below by converting the created_at to MM-YYYY format

SELECT COUNT(*) AS records_before_created_at
FROM interest_metrics AS me
INNER JOIN interest_map AS ma ON me.interest_id::INT = ma.id
WHERE me.month_year < TO_DATE(TO_CHAR(ma.created_at, 'MM-YYYY'), 'MM-YYYY');

--Seems good, I am getting no counted records. So these records are valid.