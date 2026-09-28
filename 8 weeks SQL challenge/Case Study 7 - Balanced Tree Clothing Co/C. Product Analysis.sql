SELECT *
FROM product_details

SELECT *
FROM product_hierarchy

SELECT *
FROM product_prices

SELECT *
FROM sales

------------------------C. Product Analysis------------------------

/*1.  What are the top 3 products by total revenue before discount?*/

SELECT pd.product_name,
       SUM(s.qty * s.price) AS total_revenue
FROM sales AS s
LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
GROUP BY pd.product_name
ORDER BY total_revenue DESC;

/*2.  What is the total quantity, revenue and discount for each segment?*/

SELECT pd.segment_id,
       pd.segment_name,
       SUM(s.qty) AS total_quantity,
       SUM(s.qty * s.price) AS total_revenue,
       ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS total_discount
FROM sales AS s
LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
GROUP BY pd.segment_id, pd.segment_name
ORDER BY pd.segment_id;

/*3.  What is the top selling product for each segment?*/

WITH cte AS (
    SELECT pd.segment_id,
           pd.segment_name,
           pd.product_name,
           SUM(s.qty) AS total_quantity,
           DENSE_RANK() OVER (
               PARTITION BY pd.segment_id
               ORDER BY SUM(s.qty) DESC
           ) AS rnk
    FROM sales AS s
    LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
    GROUP BY pd.segment_id, pd.segment_name, pd.product_name
)
SELECT segment_id,
       segment_name,
       product_name,
       total_quantity
FROM cte
WHERE rnk = 1;

/*4.  What is the total quantity, revenue and discount for each category?*/

SELECT pd.category_id,
       pd.category_name,
       SUM(s.qty) AS total_quantity,
       SUM(s.qty * s.price) AS total_revenue,
       ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS total_discount
FROM sales AS s
LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
GROUP BY pd.category_id, pd.category_name
ORDER BY pd.category_id;

/*5.  What is the top selling product for each category?*/

WITH cte AS (
    SELECT pd.category_id,
           pd.category_name,
           pd.product_name,
           SUM(s.qty) AS total_quantity,
           DENSE_RANK() OVER (
               PARTITION BY pd.category_id
               ORDER BY SUM(s.qty) DESC
           ) AS rnk
    FROM sales AS s
    LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
    GROUP BY pd.category_id, pd.category_name, pd.product_name
)
SELECT category_id,
       category_name,
       product_name,
       total_quantity
FROM cte
WHERE rnk = 1;

/*6.  What is the percentage split of revenue by product for each segment?*/

WITH cte AS (
    SELECT pd.segment_id,
           pd.segment_name,
           pd.product_name,
           SUM(s.qty * s.price) AS total_revenue
    FROM sales AS s
    LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
    GROUP BY pd.segment_id, pd.segment_name, pd.product_name
)
SELECT segment_id,
       segment_name,
       product_name,
       total_revenue,
       CONCAT(
           ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (PARTITION BY segment_id), 2),
           '%'
       ) AS total_revenue_percentage
FROM cte
ORDER BY segment_id, total_revenue_percentage DESC;

/*7.  What is the percentage split of revenue by segment for each category?*/

WITH cte AS (
    SELECT pd.segment_id,
           pd.segment_name,
           pd.category_name,
           SUM(s.qty * s.price) AS total_revenue
    FROM sales AS s
    LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
    GROUP BY pd.segment_id, pd.segment_name, pd.category_name
)
SELECT segment_id,
       segment_name,
       category_name,
       total_revenue,
       CONCAT(
           ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (PARTITION BY category_name), 2),
           '%'
       ) AS total_revenue_percentage
FROM cte
ORDER BY segment_id, total_revenue_percentage DESC;

/*8.  What is the percentage split of total revenue by category?*/

WITH cte AS (
    SELECT pd.category_id,
           pd.category_name,
           SUM(s.qty * s.price) AS total_revenue
    FROM sales AS s
    LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
    GROUP BY pd.category_id, pd.category_name
)
SELECT category_id,
       category_name,
       total_revenue,
       CONCAT(ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (), 2), '%') AS total_revenue_percentage
FROM cte
ORDER BY category_id, total_revenue_percentage DESC;

/*9.  What is the total transaction “penetration” for each product? 
(hint: penetration = number of transactions where at least 1 quantity 
of a product was purchased divided by total number of transactions)*/

WITH cte AS (
    SELECT pd.product_id,
           pd.product_name,
           COUNT(DISTINCT s.txn_id) AS product_transactions
    FROM sales AS s
    LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
    GROUP BY pd.product_id, pd.product_name
)
SELECT product_id,
       product_name,
       CONCAT(
           ROUND(100.0 * product_transactions / (SELECT COUNT(DISTINCT txn_id) FROM sales), 2),
           '%'
       ) AS penetration
FROM cte
ORDER BY penetration DESC;

/*10.  What is the most common combination of at least 1 quantity of any 3 products in a 1 
single transaction?*/

WITH cte AS (
        SELECT s1.prod_id AS product_1,
                     s2.prod_id AS product_2,
                     s3.prod_id AS product_3
        FROM sales AS s1
        JOIN sales AS s2 ON s1.txn_id = s2.txn_id AND s1.prod_id < s2.prod_id
        JOIN sales AS s3 ON s1.txn_id = s3.txn_id AND s2.prod_id < s3.prod_id
)
SELECT pd1.product_name AS product_1,
             pd2.product_name AS product_2,
             pd3.product_name AS product_3,
             COUNT(*) AS combination_count
FROM cte AS cte
JOIN product_details AS pd1 ON cte.product_1 = pd1.product_id
JOIN product_details AS pd2 ON cte.product_2 = pd2.product_id
JOIN product_details AS pd3 ON cte.product_3 = pd3.product_id
GROUP BY
        pd1.product_name,
        pd2.product_name,
        pd3.product_name
ORDER BY combination_count DESC;