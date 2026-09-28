SELECT *
FROM interest_map

SELECT *
FROM interest_metrics

------------------------C. Segment Analysis------------------------

/*1.  Using our filtered dataset by removing the interests with less than 6 months worth of data, 
which are the top 10 and bottom 10 interests which have the largest composition values in any 
month_year? Only use the maximum composition value for each interest but you must keep the 
corresponding month_year*/

WITH cte AS ( --CTE for interests more than 6 months 
    SELECT interest_id::INT AS interest_id
    FROM interest_metrics
    GROUP BY interest_id::INT
    HAVING COUNT(DISTINCT month_year) >= 6
),
cte1 AS ( --CTE for ranking composition
    SELECT
        me.interest_id::INT AS interest_id,
        ma.interest_name,
        me.month_year,
        me.composition,
        ROW_NUMBER() OVER (
            PARTITION BY me.interest_id::INT
            ORDER BY me.composition DESC
        ) AS rnk
    FROM interest_metrics AS me
    JOIN interest_map AS ma ON me.interest_id::INT = ma.id
    WHERE me.interest_id::INT IN (SELECT interest_id FROM cte)
),
cte2 AS ( --CTE for getting largest composition  from the ranked one's
    SELECT interest_id,
           interest_name,
           month_year,
           composition
    FROM cte1
    WHERE rnk = 1
),
cte3 AS ( --CTE for extracting top 10 and allocating category to it 
    SELECT interest_id,
           interest_name,
           month_year,
           composition,
           'Top 10' AS category
    FROM cte2
    ORDER BY composition DESC
    LIMIT 10
),
cte4 AS ( --CTE for extractig bottom 10 and allocating category to it
    SELECT interest_id,
           interest_name,
           month_year,
           composition,
           'Bottom 10' AS category
    FROM cte2
    ORDER BY composition ASC
    LIMIT 10
)
SELECT *
FROM cte3
UNION ALL
SELECT *
FROM cte4;

/*2.  Which 5 interests had the lowest average ranking value?*/

SELECT me.interest_id,
       ma.interest_name,
       ROUND(AVG(me.ranking), 1) AS avg_ranking,
       COUNT(*) AS record_count
FROM fresh_segments.interest_metrics AS me
JOIN interest_map AS ma ON me.interest_id::INT = ma.id
WHERE me.month_year IS NOT NULL
GROUP BY ma.interest_name, me.interest_id
ORDER BY avg_ranking
LIMIT 5;

/*3.  Which 5 interests had the largest standard deviation in their percentile_ranking value?*/

WITH cte AS (
    SELECT interest_id::INT AS interest_id
    FROM interest_metrics
    GROUP BY interest_id::INT
    HAVING COUNT(DISTINCT month_year) >= 6
)
SELECT ma.interest_name,
       ROUND(CAST(STDDEV(me.percentile_ranking) AS numeric), 2) AS stddev_percentile_ranking,
       COUNT(*) AS record_count
FROM interest_metrics AS me
JOIN interest_map AS ma ON me.interest_id::INT = ma.id
WHERE me.interest_id::INT IN (SELECT interest_id FROM cte)
GROUP BY ma.interest_name
ORDER BY stddev_percentile_ranking DESC NULLS LAST
LIMIT 5;

/*4.  For the 5 interests found in the previous question - what was minimum and maximum 
percentile_ranking values for each interest and its corresponding year_month value? 
Can you describe what is happening for these 5 interests?*/

WITH cte AS (
    SELECT me.interest_id::INT AS interest_id,
           ma.interest_name
    FROM interest_metrics AS me
    JOIN interest_map AS ma ON me.interest_id::INT = ma.id
    GROUP BY me.interest_id::INT, ma.interest_name
    ORDER BY STDDEV(me.percentile_ranking) DESC NULLS LAST
    LIMIT 5
),
cte1 AS (
    SELECT
        me.interest_id::INT AS interest_id,
        cte.interest_name,
        me.month_year,
        me.percentile_ranking,
        ROW_NUMBER() OVER (
            PARTITION BY me.interest_id::INT
            ORDER BY me.percentile_ranking ASC
        ) AS min_rnk,
        ROW_NUMBER() OVER (
            PARTITION BY me.interest_id::INT
            ORDER BY me.percentile_ranking DESC
        ) AS max_rnk
    FROM interest_metrics AS me
    JOIN cte AS cte ON me.interest_id::INT = cte.interest_id
)
SELECT
    interest_name,
    MAX(CASE WHEN min_rnk = 1 THEN month_year END) AS min_month_year,
    MAX(CASE WHEN min_rnk = 1 THEN percentile_ranking END) AS min_percentile_ranking,
    MAX(CASE WHEN max_rnk = 1 THEN month_year END) AS max_month_year,
    MAX(CASE WHEN max_rnk = 1 THEN percentile_ranking END) AS max_percentile_ranking
FROM cte1
GROUP BY interest_name
ORDER BY interest_name;

/*5.  How would you describe our customers in this segment based off their composition 
and ranking values? What sort of products or services should we show to these customers 
and what should we avoid?*/

--Not a coding question but based on the details of these 5 volatile interests 
--(Android Fans, Blockbuster Movie Fans, Entertainment Industry Decision Makers, Techies, and TV Junkies)
--Show: Flash sales, flagship gadgets, streaming passes, and limited-edition tech merchandise.
--Avoid: Long-term contracts, high-value financial products, or household staples.