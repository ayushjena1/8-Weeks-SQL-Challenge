SELECT *
FROM members

SELECT *
FROM sales

SELECT *
FROM menu

------------------------Case Study Questions------------------------

/*1. What is the total amount each customer spent at the restaurant?*/

SELECT s.customer_id,
       SUM(m.price) AS total_spent
FROM sales AS s
INNER JOIN menu AS m ON s.product_id = m.product_id
GROUP BY s.customer_id;

/*2. How many days has each customer visited the restaurant?*/

SELECT customer_id,
       COUNT(DISTINCT order_date) AS total_visits
FROM sales
GROUP BY customer_id;

/*3. What was the first item from the menu purchased by each customer?*/

WITH first_purchase AS (
    SELECT s.customer_id,
           m.product_name,
           ROW_NUMBER() OVER (
               PARTITION BY s.customer_id
               ORDER BY s.order_date, s.product_id
           ) AS first_purchased_item
    FROM sales AS s
    INNER JOIN menu as m ON s.product_id = m.product_id
)
SELECT customer_id,
       product_name
FROM first_purchase
WHERE first_purchased_item = 1;

/*4. What is the most purchased item on the menu and how many times was it purchased by all customers?*/

SELECT m.product_name,
       COUNT(s.product_id) AS total_purchases
FROM sales AS s
LEFT JOIN menu AS m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchases DESC
LIMIT 1;

/*5. Which item was the most popular for each customer?*/

WITH most_popular_item AS (
    SELECT s.customer_id,
           m.product_name,
           DENSE_RANK() OVER (
               PARTITION BY s.customer_id
               ORDER BY COUNT(s.product_id) DESC
           ) AS rank
    FROM sales AS s
    LEFT JOIN menu AS m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id,
       product_name
FROM most_popular_item
WHERE rank = 1;

/*6. Which item was purchased first by the customer after they became a member?*/

WITH first_order_after_membership AS (
    SELECT s.customer_id,
           m.product_name,
           c.join_date,
           DENSE_RANK() OVER (
               PARTITION BY s.customer_id
               ORDER BY s.order_date
           ) AS rank
    FROM sales AS s
    LEFT JOIN members AS c ON s.customer_id = c.customer_id
    LEFT JOIN menu AS m ON s.product_id = m.product_id
    WHERE s.order_date >= c.join_date
)
SELECT *
FROM first_order_after_membership
WHERE rank = 1;

/*7. Which item was purchased just before the customer became a member?*/

WITH order_before_membership AS (
    SELECT s.customer_id,
           m.product_name,
           c.join_date,
           DENSE_RANK() OVER (
               PARTITION BY s.customer_id
               ORDER BY s.order_date DESC
           ) AS rank
    FROM sales AS s
    LEFT JOIN members AS c ON s.customer_id = c.customer_id
    LEFT JOIN menu AS m ON s.product_id = m.product_id
    WHERE s.order_date < c.join_date
)
SELECT *
FROM order_before_membership
WHERE rank = 1;

/*8. What is the total items and amount spent for each member before they became a member?*/

SELECT s.customer_id,
       COUNT(m.product_name) AS total_items,
       SUM(m.price) AS total_spent,
       c.join_date
FROM sales AS s
LEFT JOIN menu AS m ON s.product_id = m.product_id
LEFT JOIN members AS c ON s.customer_id = c.customer_id
WHERE s.order_date < c.join_date
GROUP BY s.customer_id, c.join_date;

/*9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier, how many points 
would each customer have?*/


SELECT s.customer_id,
       SUM(
           CASE m.product_name
               WHEN 'sushi' THEN m.price * 20
               ELSE price * 10
           END
       ) AS points
FROM sales AS s
LEFT JOIN menu AS m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY points DESC;


/*10. In the first week after a customer joins the program (including their join date) they earn 2x 
points on all items, not just sushi - how many points do customer A and B have at the end of January?*/

WITH cte AS (
    SELECT s.customer_id,
           m.product_name,
           m.price,
           c.join_date,
           s.order_date,
           CASE
               WHEN m.product_name = 'sushi' THEN m.price * 20
               WHEN s.order_date BETWEEN c.join_date AND (c.join_date + 6) THEN m.price * 20
               ELSE m.price * 10
           END AS points
    FROM sales AS s
    JOIN members AS c ON s.customer_id = c.customer_id
    JOIN menu AS m ON s.product_id = m.product_id
    WHERE s.order_date BETWEEN '01-01-2021' AND '02-01-2021'
)
SELECT customer_id,
       SUM(points) AS total_points
FROM cte
GROUP BY customer_id;

/*11:  Determine the name and price of the product ordered by each customer on all order dates & find 
out whether the customer was a member on the order date or not*/

SELECT s.customer_id,
       m.product_name,
       m.price,
       c.join_date,
       s.order_date,
       CASE
           WHEN s.order_date >= c.join_date THEN 'YES'
           ELSE 'NO'
       END AS member_check
FROM sales AS s
LEFT JOIN menu AS m ON s.product_id = m.product_id
LEFT JOIN members AS c ON s.customer_id = c.customer_id
ORDER BY s.customer_id, m.product_name, m.price DESC

/*12:  Rank the previous output from Q.11 based on the order_date for each customer. Display 
NULL if customer was not a member when dish was ordered.*/

WITH cte AS (
    SELECT s.customer_id,
           m.product_name,
           m.price,
           c.join_date,
           s.order_date,
           CASE
               WHEN s.order_date >= c.join_date THEN 'YES'
               ELSE 'NO'
           END AS member_check
    FROM sales AS s
    LEFT JOIN menu AS m ON s.product_id = m.product_id
    LEFT JOIN members AS c ON s.customer_id = c.customer_id
    ORDER BY s.customer_id, m.product_name, m.price DESC
)
SELECT *,
       CASE
           WHEN member_check = 'NO' THEN NULL
           ELSE RANK() OVER (
               PARTITION BY customer_id, member_check
               ORDER BY order_date
           )
       END AS rank
FROM cte