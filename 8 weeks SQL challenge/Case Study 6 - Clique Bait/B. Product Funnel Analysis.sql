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

------------------------B. Product Funnel Analysis------------------------

/*Using a single SQL query - create a new output table which has the following details:

--How many times was each product viewed?
--How many times was each product added to cart?
--How many times was each product added to a cart but not purchased (abandoned)?
--How many times was each product purchased?*/

CREATE VIEW product_summary_view AS
WITH cte AS (
    SELECT visit_id,
           SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase_visits
    FROM events
    GROUP BY visit_id
)
SELECT p.product_id,
       p.page_name AS product_name,
       p.product_category,
       SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) product_views,
       SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) added_to_cart,
       SUM(CASE WHEN event_type = 2 AND c.purchase_visits = 0 THEN 1 ELSE 0 END) AS abandoned,
       SUM(CASE WHEN event_type = 2 AND c.purchase_visits = 1 THEN 1 ELSE 0 END) AS purchased_product
FROM events AS e
JOIN page_hierarchy AS p ON p.page_id = e.page_id
JOIN cte AS c ON c.visit_id = e.visit_id
WHERE p.product_id IS NOT NULL
GROUP BY p.product_id, p.page_name, p.product_category
ORDER BY p.product_id;

/*Additionally, create another table which further aggregates the data for the above points but this 
time for each product category instead of individual products.*/

CREATE VIEW category_summary_view AS
SELECT product_category,
       SUM(product_views) AS views,
       SUM(added_to_cart) AS cart_adds,
       SUM(abandoned) AS abandoned,
       SUM(purchased_product) AS purchases
FROM product_summary_view
GROUP BY product_category
ORDER BY product_category;

/*Use your 2 new output tables - answer the following questions:*/

/*1.  Which product had the most views, cart adds and purchases?*/

--Most Views
SELECT product_name,
       product_views
FROM product_summary_view
ORDER BY product_views DESC
LIMIT 1;

--Most Cart Adds
SELECT product_name,
       added_to_cart
FROM product_summary_view
ORDER BY added_to_cart DESC
LIMIT 1;

--Most Purchases
SELECT product_name,
       purchased_product
FROM product_summary_view
ORDER BY purchased_product DESC
LIMIT 1;

/*2.  Which product was most likely to be abandoned?*/

SELECT product_name,
       purchased_product
FROM product_summary_view
ORDER BY abandoned DESC
LIMIT 1;

/*3.  Which product had the highest view to purchase percentage?*/

SELECT product_name,
       CONCAT(ROUND(100.0 * purchased_product / product_views, 2), '%') AS percentage
FROM product_summary_view
ORDER BY percentage DESC LIMIT 1;

/*4.  What is the average conversion rate from view to cart add?*/

SELECT CONCAT(ROUND(100.0 * SUM(added_to_cart) / SUM(product_views), 2), '%') AS avg_conversion
FROM product_summary_view;

/*5.  What is the average conversion rate from cart add to purchase?*/

SELECT CONCAT(ROUND(100.0 * SUM(purchased_product) / SUM(added_to_cart), 2), '%') AS avg_conversion
FROM product_summary_view;