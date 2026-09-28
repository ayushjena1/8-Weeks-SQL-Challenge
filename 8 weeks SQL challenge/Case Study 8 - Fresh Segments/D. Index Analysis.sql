SELECT *
FROM interest_map

SELECT *
FROM interest_metrics

------------------------D. Index Analysis------------------------

/*The index_value is a measure which can be used to reverse calculate the average composition 
for Fresh Segments’ clients. Average composition can be calculated by dividing the composition 
column by the index_value column rounded to 2 decimal places.*/

/*1.  What is the top 10 interests by the average composition for each month?*/

WITH cte AS (
    SELECT me.month_year,
           ma.interest_name,
           ROUND((me.composition / me.index_value)::NUMERIC, 2) AS avg_composition,
           DENSE_RANK() OVER (
               PARTITION BY me.month_year
               ORDER BY me.composition / me.index_value DESC
           ) AS rnk
    FROM interest_metrics AS me
    JOIN interest_map AS ma ON me.interest_id::INT = ma.id
)
SELECT month_year,
       interest_name,
       avg_composition,
       rnk
FROM cte
WHERE rnk <= 10
ORDER BY month_year, rnk;

/*2.  For all of these top 10 interests - which interest appears the most often?*/

WITH cte AS (
    SELECT
        me.month_year,
        ma.interest_name,
        ROUND((me.composition / me.index_value)::NUMERIC, 2) AS avg_composition,
        DENSE_RANK() OVER (
            PARTITION BY me.month_year
            ORDER BY (me.composition / me.index_value) DESC
        ) AS rnk
    FROM interest_metrics AS me
    JOIN interest_map AS ma ON me.interest_id::INT = ma.id
)
SELECT interest_name,
       COUNT(*) AS top_10
FROM cte
WHERE rnk <= 10
GROUP BY interest_name
ORDER BY top_10 DESC, interest_name ASC;

/*3.  What is the average of the average composition for the top 10 interests for each month?*/

WITH cte AS (
    SELECT me.month_year,
           ma.interest_name,
           (me.composition / me.index_value) AS avg_composition,
           DENSE_RANK() OVER (
               PARTITION BY me.month_year
               ORDER BY (me.composition / me.index_value) DESC
           ) AS rnk
    FROM interest_metrics AS me
    JOIN interest_map AS ma ON me.interest_id::INT = ma.id
)
SELECT month_year,
       ROUND(AVG(avg_composition)::NUMERIC, 2) AS avg_top10_composition
FROM cte
WHERE rnk <= 10
GROUP BY month_year
ORDER BY month_year ASC;

/*4.  What is the 3 month rolling average of the max average composition value from September 2018 to
August 2019 and include the previous top ranking interests in the same output shown below.*/

WITH cte AS ( --CTE to get average maximum composition
    SELECT me.month_year,
           ma.interest_name,
           ROUND(MAX(me.composition / me.index_value)::NUMERIC, 2) AS max_composition
    FROM interest_metrics AS me
    JOIN interest_map AS ma ON me.interest_id::INT = ma.id
    GROUP BY me.month_year, ma.interest_name
),
cte1 AS ( --CTE for ranking the intrests as per maximum composition
    SELECT month_year,
           interest_name,
           max_composition,
           DENSE_RANK() OVER (PARTITION BY month_year ORDER BY max_composition DESC) AS rnk
    FROM cte
),
cte2 AS ( --CTE for getting the top rank interest
    SELECT month_year,
           interest_name,
           max_composition
    FROM cte1
    WHERE rnk = 1
),
cte3 AS ( --CTE for rolling average
    SELECT month_year,
           interest_name,
           max_composition,
           ROUND(
               AVG(max_composition) OVER (
                   ORDER BY month_year
                   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
               )::NUMERIC,
               2
           ) AS "3_month_moving_avg",
           LAG(interest_name, 1) OVER (ORDER BY month_year) || ': ' ||
           LAG(max_composition, 1) OVER (ORDER BY month_year) AS "1_month_ago",
           LAG(interest_name, 2) OVER (ORDER BY month_year) || ': ' ||
           LAG(max_composition, 2) OVER (ORDER BY month_year) AS "2_months_ago"
    FROM cte2
)
SELECT month_year,
       interest_name,
       max_composition,
       "3_month_moving_avg",
       "1_month_ago",
       "2_months_ago"
FROM cte3
WHERE month_year >= '2018-09-01'
ORDER BY month_year ASC;

/*5.  Provide a possible reason why the max average composition might change from month to month? 
Could it signal something is not quite right with the overall business model for Fresh Segments?*/

--Seasonal shifts and promotional campaigns cause monthly changes in max average composition.
--Business Risk:- Yes, too many changes make audience targeting unpredictable for advertisers, 
--making long-term ad subscriptions hard to sell and customer drop rate increases.