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


---------------------B. Runner and Customer Experience---------------------

/*1.  How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01) */

SELECT ((registration_date - '2021-01-01') / 7) + 1 AS signed_ups,
	   COUNT(runner_id) AS runner_id
FROM runners
GROUP BY signed_ups
ORDER BY signed_ups;

/*2.  What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ
to pickup the order? */

WITH cte AS (
	SELECT ro.runner_id,
		   (EXTRACT(HOUR FROM (ro.pickup_time - c.order_time)) * 60)
		   + EXTRACT(MINUTE FROM (ro.pickup_time - c.order_time)) AS time_in_min
	FROM runner_orders AS ro
	JOIN customer_orders AS c on c.order_id = ro.order_id
)
SELECT runner_id,
	   CONCAT(ROUND(AVG(time_in_min)), 'min') AS avg_time
FROM cte
GROUP BY runner_id
ORDER BY runner_id;


/*3.  Is there any relationship between the number of pizzas and how long the order takes to prepare? */

WITH cte AS (
	SELECT c.order_id,
		   COUNT(c.pizza_id) AS pizza,
		   (EXTRACT(HOUR FROM (ro.pickup_time - c.order_time)) * 60)
		   + EXTRACT(MINUTE FROM (ro.pickup_time - c.order_time)) AS time_in_min
	FROM customer_orders AS c
	JOIN runner_orders AS ro ON c.order_id = ro.order_id
	WHERE ro.cancellation IS NULL
	GROUP BY c.order_id, time_in_min
)
SELECT pizza,
	   AVG(time_in_min)
FROM cte
GROUP BY pizza;

/*4.  What was the average distance travelled for each customer? */

SELECT c.customer_id,
	   CONCAT(ROUND(AVG(ro.distance), 2), 'km') AS avg_distance
FROM customer_orders AS c
JOIN runner_orders AS ro ON c.order_id = ro.order_id
WHERE ro.distance IS NOT NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;
/*OR if you want to know avg distance travelled by each runner */

SELECT ro.runner_id,
	   CONCAT(ROUND(AVG(ro.distance), 2), 'km') AS avg_distance
FROM runner_orders AS ro
WHERE ro.distance IS NOT NULL
GROUP BY ro.runner_id
ORDER BY ro.runner_id;

/*5.  What was the difference between the longest and shortest delivery times for all orders? */

SELECT CONCAT(MAX(duration) - MIN(duration), 'km') AS delivery_diff
FROM runner_orders;

/*6.  What was the average speed for each runner for each delivery and do you notice any trend for
these values? */

SELECT order_id,
	   runner_id,
	   CONCAT(ROUND(AVG(distance / (duration / 60.0)), 2), 'km/h') AS avg_speed
-- Function AVG is not necessary since each order_id appear once in the table.
--I just used it cuz the question says so -_-
FROM runner_orders
WHERE distance IS NOT NULL
	AND duration IS NOT NULL
GROUP BY order_id, runner_id
ORDER BY order_id;

/*7.  What is the successful delivery percentage for each runner? */

SELECT runner_id,
	   COUNT(order_id) AS orders,
	   COUNT(pickup_time) AS delivered,
	   CONCAT(100 * COUNT(pickup_time) / COUNT(order_id), '%') AS delivery_percentage
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;