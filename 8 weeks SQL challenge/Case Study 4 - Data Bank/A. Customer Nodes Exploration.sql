ALTER USER postgres SET search_path TO data_bank, public;
SET search_path = data_bank;

SELECT *
FROM regions

SELECT *
FROM customer_nodes

SELECT *
FROM customer_transactions

------------------------A. Customer Nodes Exploration------------------------

/*1.  How many unique nodes are there on the Data Bank system?*/

SELECT COUNT(DISTINCT node_id) AS unique_nodes_count
FROM customer_nodes;

/*2.  What is the number of nodes per region?*/

SELECT r.region_name,
       COUNT(DISTINCT c.node_id) AS node_counts
FROM customer_nodes AS c
JOIN regions AS r ON r.region_id = c.region_id
GROUP BY r.region_name;

/*3.  How many customers are allocated to each region?*/

SELECT r.region_name,
       COUNT(DISTINCT c.customer_id) AS customer_counts
FROM customer_nodes AS c
JOIN regions AS r ON r.region_id = c.region_id
GROUP BY r.region_name;

/*4.  How many days on average are customers reallocated to a different node?*/

SELECT ROUND(AVG(end_date - start_date)) AS avg_days
FROM customer_nodes
WHERE end_date != '9999-12-31';

/*5.  What is the median, 80th and 95th percentile for this same reallocation days metric for each region?*/

WITH cte AS (
    SELECT c.region_id,
           r.region_name,
           c.end_date - c.start_date AS duration
    FROM customer_nodes AS c
    JOIN regions AS r ON r.region_id = c.region_id
    WHERE end_date != '9999-12-31'
)
SELECT region_id,
       region_name,
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY duration) AS median,
       PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY duration) AS percentile_80th,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration) AS percentile_95th
FROM cte
GROUP BY region_id, region_name
ORDER BY region_id;