SELECT *
FROM interest_map

SELECT *
FROM interest_metrics

------------------------B. Interest Analysis------------------------

/*1.  Which interests have been present in all month_year dates in our dataset?*/

WITH cte AS (
    SELECT COUNT(DISTINCT month_year) AS total_count
    FROM interest_metrics
),
cte1 AS (
    SELECT interest_id::INT,
           COUNT(DISTINCT month_year) AS total_months_present
    FROM interest_metrics
    GROUP BY interest_id::INT
)
SELECT interest_id::INT,
       total_months_present
FROM cte1
WHERE total_months_present = (SELECT total_count FROM cte)
ORDER BY interest_id::INT;

--Total unique months in dataset is 14
--Total qualifying interest_ids is 480

/*2.  Using this same total_months measure - calculate the cumulative percentage of all records
 starting at 14 months - which total_months value passes the 90% cumulative percentage value?*/

WITH cte AS (
    SELECT interest_id::INT,
           COUNT(DISTINCT month_year) AS total_months_present
    FROM interest_metrics
    GROUP BY interest_id::INT
),
cte1 AS (
    SELECT total_months_present,
           COUNT(interest_id) AS interest_count
    FROM cte
    GROUP BY total_months_present
),
cte2 AS (
    SELECT total_months_present,
           interest_count,
           ROUND(
               100.0 * SUM(interest_count) OVER (ORDER BY total_months_present DESC)
               / SUM(interest_count) OVER (),
               2
           ) AS cumulative_percentage
    FROM cte1
)
SELECT *
FROM cte2
WHERE cumulative_percentage >= 90
ORDER BY total_months_present DESC;

/*3.  If we were to remove all interest_id values which are lower than the total_months value 
we found in the previous question - how many total data points would we be removing?*/

WITH cte AS (
    SELECT interest_id::INT,
           COUNT(DISTINCT month_year) AS total_months_present
    FROM interest_metrics
    WHERE interest_id IS NOT NULL
    GROUP BY interest_id::INT
),
cte1 AS (
    SELECT interest_id
    FROM cte
    WHERE total_months_present < 6
)
SELECT COUNT(*) AS removed_data_points
FROM interest_metrics
WHERE interest_id::INT IN (SELECT interest_id FROM cte1);

/*4.  Does this decision make sense to remove these data points from a business perspective? 
Use an example where there are all 14 months present to a removed interest example for your
arguments - think about what it means to have less months present from a segment perspective.*/

--It can be a both yes/no answer.
--Yes because filtering out segments that appear in fewer than 6 months focuses on long-term customers.
--No because the duration is not that long to filter the customers fewer than 6 months despite of less contribution.

/*5.  After removing these interests - how many unique interests are there for each month?*/

WITH cte AS (
    SELECT interest_id::INT AS interest_id,
           COUNT(DISTINCT month_year) AS total_months_present
    FROM interest_metrics
    GROUP BY interest_id::INT
    HAVING COUNT(DISTINCT month_year) >= 6
)
SELECT month_year,
       COUNT(DISTINCT interest_id::INT) AS unique_interests_count
FROM interest_metrics
WHERE interest_id::INT IN (SELECT interest_id FROM cte)
GROUP BY month_year
ORDER BY month_year;