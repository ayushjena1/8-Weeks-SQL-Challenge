ALTER USER postgres SET search_path TO clique_bait, public;
SET search_path = clique_bait;

SELECT *
FROM event_identifier

SELECT *
FROM campaign_identifier

SELECT *
FROM events

SELECT *
FROM page_hierarchy

SELECT *
FROM users

------------------------A. Digital Analysis------------------------

/*1.  How many users are there?*/

SELECT COUNT(DISTINCT user_id) AS total_users
FROM users;

/*2.  How many cookies does each user have on average?*/

WITH cte AS (
    SELECT DISTINCT user_id, COUNT(cookie_id) AS cookie_count
    FROM users
    GROUP BY DISTINCT user_id
)
SELECT ROUND(AVG(cookie_count), 2) AS avg_per_user
FROM cte;

/*3.  What is the unique number of visits by all users per month?*/

SELECT EXTRACT(MONTH FROM event_time) AS monthly,
       COUNT(DISTINCT visit_id) AS number_of_visits
FROM events
GROUP BY EXTRACT(MONTH FROM event_time)
ORDER BY monthly_visit;

/*4.  What is the number of events for each event type?*/

SELECT ei.event_type,
       ei.event_name,
       COUNT(e.event_type) AS number_of_events
FROM events AS e
LEFT JOIN event_identifier AS ei ON ei.event_type = e.event_type
GROUP BY ei.event_type, ei.event_name
ORDER BY ei.event_type;

/*5.  What is the percentage of visits which have a purchase event?*/

SELECT CONCAT(
       ROUND(
         100.0 * COUNT(DISTINCT e.visit_id) /
         (SELECT COUNT(DISTINCT visit_id) FROM events),
         2
       ),
       '%'
     ) AS percent_of_visits
FROM events AS e
LEFT JOIN event_identifier AS ei ON ei.event_type = e.event_type
WHERE ei.event_name = 'Purchase';

/*6.  What is the percentage of visits which view the checkout page but do not have a purchase event?*/

WITH cte AS (
  SELECT visit_id,
       SUM(CASE WHEN page_id = 12 AND event_type = 1 THEN 1 ELSE 0 END) AS visited_checkout,
       SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS made_purchase
    FROM events
    GROUP BY visit_id
)
SELECT CONCAT(ROUND(100 * (1 - SUM(made_purchase) / SUM(visited_checkout)), 2), '%') AS no_purchase
FROM cte;

/*7.  What are the top 3 pages by number of views?*/

SELECT p.page_id,
       p.page_name,
       COUNT(e.event_type) AS page_views
FROM events AS e
LEFT JOIN page_hierarchy AS p ON e.page_id = p.page_id
JOIN event_identifier AS ei ON ei.event_type = e.event_type
WHERE ei.event_name = 'Page View'
GROUP BY p.page_id, p.page_name
ORDER BY page_views DESC;

/*8.  What is the number of views and cart adds for each product category?*/

SELECT p.product_category,
       SUM(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds,
       SUM(CASE WHEN ei.event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views
FROM events AS e
LEFT JOIN page_hierarchy AS p ON e.page_id = p.page_id
JOIN event_identifier AS ei ON ei.event_type = e.event_type
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category;

/*9.  What are the top 3 products by purchases?*/

WITH cte AS (
    SELECT DISTINCT visit_id
    FROM events
    WHERE event_type = 3
)
SELECT p.page_name, COUNT(*) AS purchase_count
FROM events AS e
JOIN page_hierarchy AS p ON e.page_id = p.page_id
JOIN cte AS c ON e.visit_id = c.visit_id
WHERE e.event_type = 2
  AND p.product_id IS NOT NULL
GROUP BY p.page_name
ORDER BY purchase_count DESC;