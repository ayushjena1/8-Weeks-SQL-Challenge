SELECT *
FROM cleaned_customer_orders

SELECT *
FROM runner_orders

SELECT *
FROM pizza_names

SELECT *
FROM cleaned_pizza_recipes

SELECT *
FROM pizza_toppings

SELECT *
FROM runners


---------------------D.  Pricing and Ratings---------------------

/*1.  If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
how much money has Pizza Runner made so far if there are no delivery fees?*/

SELECT SUM(
       CASE
         WHEN c.pizza_id = 1 THEN 12
         ELSE 10
       END
     ) AS total_earned
FROM customer_orders AS c /*Don't use cleaned_customer_order table for financial calculation since it have 
                           duplicates that was created for previous exercise of Ingredient Optimisation. 
                           If you wish to use make sure you are using DISTINCT*/
LEFT JOIN runner_orders AS ro ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL;

/*2.  What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra*/

WITH cte AS ( --CTE for total earning
  SELECT SUM(
         CASE
           WHEN c.pizza_id = 1 THEN 12
           ELSE 10
         END
       ) AS total_earned
  FROM customer_orders AS c
  LEFT JOIN runner_orders AS ro ON c.order_id = ro.order_id
  WHERE ro.cancellation IS NULL
),
cte1 AS ( --CTE for addiional charge earning
  SELECT COUNT(c.extra_id) AS added
  FROM cleaned_customer_orders AS c --Using cleaned_customer_order table because of toppings and counting them
  LEFT JOIN runner_orders AS ro ON c.order_id = ro.order_id
  WHERE ro.cancellation IS NULL
)
SELECT total_earned + added AS added_total
FROM cte, cte1;

/*3.  The Pizza Runner team now wants to add an additional ratings system that allows customers to rate 
their runner, how would you design an additional table for this new dataset - generate a schema for this
 new table and insert your own data for ratings for each successful customer order between 1 to 5.*/

DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
    rating_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    runner_id INTEGER NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5)
);

INSERT INTO runner_ratings (order_id, runner_id, rating)
VALUES
    (1, 1, 5),
    (2, 1, 4),
    (3, 1, 5),
    (4, 2, 3),
    (5, 3, 5),
    (7, 2, 4),
    (8, 2, 5),
    (10, 1, 5);

SELECT *
FROM runner_ratings;

/*4.  Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas*/

SELECT c.order_id,
     c.customer_id,
     ro.runner_id,
     ra.rating,
     c.order_time,
     ro.pickup_time,
     CONCAT(
       (EXTRACT(HOUR FROM (ro.pickup_time - c.order_time)) * 60)
       + EXTRACT(MINUTE FROM (ro.pickup_time - c.order_time)),
       ' min'
     ) AS preparation_time,
     CONCAT(ro.duration, ' min') AS delivery_duration,
     CONCAT(ROUND(AVG(distance / (duration / 60.0)), 2), ' km/h') AS avg_speed,
     COUNT(c.pizza_id) AS total_pizzas
FROM customer_orders AS c
LEFT JOIN runner_orders AS ro ON ro.order_id = c.order_id
LEFT JOIN runner_ratings AS ra ON c.order_id = ra.order_id
WHERE ro.cancellation IS NULL
GROUP BY c.customer_id, c.order_id, ro.runner_id, ra.rating, c.order_time, ro.pickup_time, delivery_duration
ORDER BY c.order_id;

/*5.  If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each 
runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over 
after these deliveries?*/

WITH cte AS (
  SELECT SUM(
         CASE
           WHEN c.pizza_id = 1 THEN 12
           ELSE 10
         END
       ) AS total_earned
  FROM customer_orders AS c
  LEFT JOIN runner_orders AS ro ON c.order_id = ro.order_id
  WHERE ro.cancellation IS NULL
),
cte1 AS (
    SELECT ROUND(SUM(distance * 0.30)) AS runners_earnings
    FROM runner_orders
)
SELECT total_earned,
     runners_earnings,
     total_earned - runners_earnings AS remaining_balance
FROM cte, cte1;