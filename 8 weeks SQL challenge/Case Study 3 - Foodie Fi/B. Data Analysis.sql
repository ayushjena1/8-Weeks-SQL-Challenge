SELECT *
FROM plans

SELECT *
FROM subscriptions

------------------------B. Data Analysis------------------------

/*1.  How many customers has Foodie-Fi ever had?*/

SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;

/*2.  What is the monthly distribution of trial plan start_date values for our dataset - use the start of 
the month as the group by value*/

SELECT EXTRACT(MONTH FROM start_date) AS month_num,
       COUNT(customer_id) AS trial_users
FROM subscriptions
WHERE plan_id = 0
GROUP BY month_num
ORDER BY month_num;

/*3.  What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by 
count of events for each plan_name*/

WITH cte AS (
    SELECT EXTRACT(YEAR FROM start_date) AS year_set, s.plan_id, p.plan_name
    FROM subscriptions AS s
    JOIN plans AS p ON s.plan_id = p.plan_id
)
SELECT plan_id,
       plan_name,
       COUNT(plan_id) AS event_counts
FROM cte
WHERE year_set > 2020
GROUP BY plan_id, plan_name
ORDER BY plan_id;

--OR if you wish to avoid CTE (I prefer CTE's)

SELECT p.plan_id,
       p.plan_name,
       COUNT(p.plan_id) AS event_counts
FROM subscriptions AS s
JOIN plans AS p ON p.plan_id = s.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;

/*4.  What is the customer count and percentage of customers who have churned rounded to 1 decimal place?*/

WITH cte AS (
    SELECT SUM(CASE WHEN p.plan_name = 'churn' OR p.plan_id = 4 THEN 1 ELSE 0 END) AS churn_count,
           COUNT(DISTINCT s.customer_id) AS total_customers
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
)
SELECT total_customers,
       churn_count,
       CONCAT(ROUND(100.0 * churn_count / total_customers, 1), '%') AS churn_percent
FROM cte;

/*5.  How many customers have churned straight after their initial free trial - what percentage is 
this rounded to the nearest whole number?*/

WITH cte AS (
    SELECT s.customer_id,
           p.plan_id,
           p.plan_name,
           LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
)
SELECT COUNT(DISTINCT customer_id) AS churned_users,
       CONCAT(
           ROUND(100.0 * COUNT(DISTINCT customer_id) /
                 (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1),
           '%'
       ) AS churn_percentage
FROM cte
WHERE plan_name = 'trial'
  AND next_plan = 'churn';

/*6.  What is the number and percentage of customer plans after their initial free trial?*/

WITH cte AS (
    SELECT s.customer_id,
           p.plan_id,
           p.plan_name,
           LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY p.plan_id) AS user_plans
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
)
SELECT user_plans,
       COUNT(DISTINCT customer_id) AS purchased_users,
       CONCAT(
           ROUND(100.0 * COUNT(DISTINCT customer_id) /
                 (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1),
           '%'
       ) AS purchased_user_percentage
FROM cte
WHERE plan_name = 'trial'
  AND user_plans IS DISTINCT FROM 'churn'
GROUP BY user_plans;

/*7.  What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?*/

WITH cte AS (
    SELECT s.customer_id,
           s.plan_id,
           p.plan_name,
           LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_date
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
    WHERE start_date <= '2020-12-31'
)
SELECT plan_name,
       COUNT(DISTINCT customer_id) AS purchased_users,
       CONCAT(
           ROUND(100.0 * COUNT(DISTINCT customer_id) /
                 (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1),
           '%'
       ) AS purchased_user_percentage
FROM cte
WHERE next_date IS NULL
GROUP BY plan_name
ORDER BY purchased_users;

/*8.  How many customers have upgraded to an annual plan in 2020?*/

SELECT COUNT(DISTINCT s.customer_id) AS annual_plan_customers
FROM subscriptions AS s
JOIN plans AS p ON p.plan_id = s.plan_id
WHERE EXTRACT(Year FROM s.start_date) = 2020
    AND p.plan_name = 'pro annual';

/*9.  How many days on average does it take for a customer to an annual plan from the day they
join Foodie-Fi?*/

WITH cte AS ( --CTE for start of trial date
    SELECT DISTINCT s.customer_id, s.start_date AS trial_date
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
    WHERE p.plan_name = 'trial'
),
cte1 AS ( --CTE for start of subscription date
    SELECT DISTINCT s.customer_id, s.start_date AS annual_date
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
    WHERE p.plan_name = 'pro annual'
)
SELECT ROUND(AVG(annual_date - trial_date), 1) AS avg_duration
FROM cte AS cte
JOIN cte1 AS cte1 ON cte.customer_id = cte1.customer_id;

/*10.  Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)*/

WITH cte AS ( --CTE for start of trial date
    SELECT DISTINCT s.customer_id, s.start_date AS trial_date
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
    WHERE p.plan_name = 'trial'
),
cte1 AS ( --CTE for start of subscription date
    SELECT DISTINCT s.customer_id, s.start_date AS annual_date
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
    WHERE p.plan_name = 'pro annual'
),
cte2 AS ( --CTE for extracting the durations
    SELECT cte.customer_id,
           cte.trial_date,
           cte1.annual_date,
           ((cte1.annual_date - cte.trial_date) / 30 + 1) AS duration
    FROM cte AS cte
    JOIN cte1 AS cte1 ON cte.customer_id = cte1.customer_id
)
SELECT CASE
           WHEN duration = 1 THEN CONCAT((duration - 1), ' - ', (duration * 30), ' days')
           ELSE CONCAT((duration - 1) * 30 + 1, ' - ', (duration * 30), ' days')
       END AS periods_count,
       COUNT(customer_id) AS customer_counts,
       ROUND(AVG(annual_date - trial_date), 1) AS avg_count
FROM cte2
GROUP BY duration
ORDER BY duration;

/*11.  How many customers downgraded from a pro monthly to a basic monthly plan in 2020?*/
WITH cte AS (
    SELECT s.customer_id,
           p.plan_name,
           LAG(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS pro_monthly
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
    WHERE EXTRACT(Year FROM s.start_date) = 2020
)
SELECT COUNT(customer_id) AS total_customers
FROM cte 
WHERE plan_name = 'basic monthly'
    AND pro_monthly = 'pro monthly';