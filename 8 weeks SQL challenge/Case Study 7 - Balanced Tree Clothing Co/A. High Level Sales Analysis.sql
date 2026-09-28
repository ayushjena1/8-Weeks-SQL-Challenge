ALTER USER postgres SET search_path TO balanced_tree, public;
SET search_path = balanced_tree;

SELECT *
FROM product_details

SELECT *
FROM product_hierarchy

SELECT *
FROM product_prices

SELECT *
FROM sales

------------------------A. High Level Sales Analysis------------------------

/*1.  What was the total quantity sold for all products?*/

SELECT pd.product_name,
	   SUM(s.qty) AS total_quantity
FROM sales AS s
LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
GROUP BY pd.product_name;

/*2.  What is the total generated revenue for all products before discounts?*/

SELECT pd.product_name,
	   SUM(s.qty * s.price) AS total_revenue
FROM sales AS s
LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
GROUP BY pd.product_name;

/*3.  What was the total discount amount for all products?*/

SELECT pd.product_name,
	   ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS total_discount
FROM sales AS s
LEFT JOIN product_details AS pd ON pd.product_id = s.prod_id
GROUP BY pd.product_name;