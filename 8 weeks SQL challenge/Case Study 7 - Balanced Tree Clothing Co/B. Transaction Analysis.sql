SELECT *
FROM product_details

SELECT *
FROM product_hierarchy

SELECT *
FROM product_prices

SELECT *
FROM sales

------------------------B. Transaction Analysis------------------------

/*1.  How many unique transactions were there?*/

SELECT COUNT(DISTINCT txn_id) AS unique_transaction
FROM sales;

/*2.  What is the average unique products purchased in each transaction?*/

WITH cte AS (
        SELECT txn_id,
                     COUNT(DISTINCT prod_id) AS unique_products
        FROM sales
        GROUP BY txn_id
)
SELECT ROUND(AVG(unique_products), 2) AS avg_unique_products_per_txn
FROM cte;

/*3.  What are the 25th, 50th and 75th percentile values for the revenue per transaction?*/

WITH cte AS (
    SELECT txn_id,
           SUM(qty * price) AS total_revenue
    FROM sales
    GROUP BY txn_id
)
SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_revenue) AS percentile_25th,
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) AS percentile_50th,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) AS percentile_75th
FROM cte;

/*4.  What is the average discount value per transaction?*/

WITH cte AS (
    SELECT DISTINCT txn_id,
           ROUND(SUM(qty * price * discount / 100.0), 2) AS total_discount
    FROM sales
    GROUP BY txn_id
)
SELECT ROUND(AVG(total_discount), 2) AS avg_discount
FROM cte;

/*5.  What is the percentage split of all transactions for members vs non-members?*/

WITH cte AS (
    SELECT DISTINCT txn_id, member
    FROM sales
)
SELECT
       CONCAT(
           ROUND(100.0 * SUM(CASE WHEN member = 'True' THEN 1 ELSE 0 END) / COUNT(*), 2),
           '%'
       ) AS members_percent,
       CONCAT(
           ROUND(100.0 * SUM(CASE WHEN member = 'False' THEN 1 ELSE 0 END) / COUNT(*), 2),
           '%'
       ) AS non_members_percent
FROM cte;

/*6.  What is the average revenue for member transactions and non-member transactions?*/

SELECT CASE WHEN member = 'True' THEN 'Member' ELSE 'Non-Member' END AS member_status,
       ROUND(SUM(qty * price) / COUNT(DISTINCT txn_id), 2) AS avg_transaction_revenue
FROM sales
GROUP BY member;

--OR

WITH cte AS (
    SELECT txn_id, member, SUM(qty * price) AS total_revenue
    FROM balanced_tree.sales
    GROUP BY txn_id, member
)
SELECT CASE WHEN member = true THEN 'Member' ELSE 'Non-Member' END AS member_status,
       ROUND(AVG(total_revenue), 2) AS avg_transaction_revenue
FROM cte
GROUP BY member;