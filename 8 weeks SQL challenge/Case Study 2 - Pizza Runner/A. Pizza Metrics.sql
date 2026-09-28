SELECT *
FROM customer_orders

SELECT *
FROM runner_orders

SELECT *
FROM pizza_names

SELECT *
FROM pizza_recipes

SELECT *
FROM pizza_toppings

SELECT *
FROM runners

---------------------A. Pizza Metrics---------------------

/*1.  How many pizzas were ordered? */

SELECT COUNT(order_id) AS total_pizza_order
FROM customer_orders;

/*2.  How many unique customer orders were made? */

SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders;

/*3.  How many successful orders were delivered by each runner? */

SELECT runner_id,
	   COUNT(order_id) AS successful_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

/*4.  How many of each type of pizza was delivered? */

SELECT pn.pizza_name,
	   COUNT(c.pizza_id) AS delivered_pizza
FROM customer_orders AS c
JOIN pizza_names AS pn ON pn.pizza_id = c.pizza_id
JOIN runner_orders AS ro ON c.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY pn.pizza_name;

--OR

SELECT c.pizza_id,
	   COUNT(c.pizza_id) AS delivered_pizza
FROM customer_orders AS c
JOIN runner_orders AS ro ON c.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY c.pizza_id;

/*5.  How many Vegetarian and Meatlovers were ordered by each customer? */

SELECT c.customer_id,
	   SUM(CASE WHEN pn.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS vegetarian_pizza,
	   SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS meatlovers_pizza
FROM customer_orders AS c
JOIN pizza_names AS pn ON pn.pizza_id = c.pizza_id
GROUP BY c.customer_id
ORDER BY c.customer_id;

/*6.  What was the maximum number of pizzas delivered in a single order? */

WITH cte AS (
	SELECT c.order_id,
		   COUNT(c.pizza_id) AS maximum_pizza
	FROM customer_orders AS c
	JOIN runner_orders AS ro ON c.order_id = ro.order_id
	WHERE ro.cancellation IS NULL
	GROUP BY c.order_id
)

SELECT MAX(maximum_pizza) AS max_no_pizza
FROM cte;

/*7.  For each customer, how many delivered pizzas had at least 1 change and how many had no changes? */

SELECT c.customer_id,
	   SUM(CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 1 ELSE 0 END) AS one_change,
	   SUM(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN 1 ELSE 0 END) AS no_change
FROM customer_orders AS c
JOIN runner_orders AS ro ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;

/*8.  How many pizzas were delivered that had both exclusions and extras? */

SELECT c.customer_id,
			 COUNT(c.pizza_id) AS modified_pizza
FROM customer_orders AS c
JOIN runner_orders AS ro ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL
	AND c.exclusions IS NOT NULL
	AND c.extras IS NOT NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;

/*9.  What was the total volume of pizzas ordered for each hour of the day? */

SELECT EXTRACT(HOUR FROM c.order_time) AS hour_of_day,
	   COUNT(pizza_id) AS pizza_volume
FROM customer_orders AS c
GROUP BY hour_of_day
ORDER BY hour_of_day;

/*10.  What was the volume of orders for each day of the week? */

SELECT TO_CHAR(c.order_time, 'Day') AS day_of_week,
	   COUNT(c.pizza_id) AS pizza_volume
FROM customer_orders AS c
GROUP BY day_of_week, EXTRACT(DOW FROM c.order_time)
ORDER BY EXTRACT(DOW FROM c.order_time);
--EXTRACT DOW function to force the day_of_week in order instead of alphabetic order