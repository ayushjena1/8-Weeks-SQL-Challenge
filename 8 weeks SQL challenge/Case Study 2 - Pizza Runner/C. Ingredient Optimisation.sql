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


---------------------C. Ingredient Optimisation---------------------

/*1.  What are the standard ingredients for each pizza?*/

SELECT n.pizza_name,
       STRING_AGG(t.topping_name, ',' ORDER BY t.topping_name) --ORDER BY is not necessary.
FROM pizza_toppings AS t
JOIN cleaned_pizza_recipes AS r ON r.topping_id = t.topping_id
JOIN pizza_names AS n ON n.pizza_id = r.pizza_id
GROUP BY n.pizza_name;

--2.  What was the most commonly added extra?

SELECT t.topping_name,
       COUNT(*) AS most_added
FROM pizza_toppings AS t
JOIN cleaned_customer_orders AS c ON t.topping_id = c.extra_id
WHERE c.extra_id IS NOT NULL
GROUP BY t.topping_name
ORDER BY most_added DESC
LIMIT 1;

/*3.  What was the most common exclusion?*/

SELECT t.topping_name,
       COUNT(*) AS most_excluded
FROM pizza_toppings AS t
JOIN cleaned_customer_orders AS c ON t.topping_id = c.exclusion_id
WHERE c.exclusion_id IS NOT NULL
GROUP BY t.topping_name
ORDER BY most_excluded DESC
LIMIT 1;

/*4.  Generate an order item for each record in the customers_orders table in the format of one 
of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/

WITH cte AS (
  SELECT c.record_id,
       c.order_id,
       c.customer_id,
       n.pizza_name,
       STRING_AGG(t.topping_name, ', ') AS add_ons,
       STRING_AGG(t1.topping_name, ', ') AS exclude
  FROM cleaned_customer_orders AS c
  LEFT JOIN pizza_names AS n ON c.pizza_id = n.pizza_id
  LEFT JOIN pizza_toppings AS t ON t.topping_id = c.extra_id
  LEFT JOIN pizza_toppings AS t1 ON t1.topping_id = c.exclusion_id
  GROUP BY c.record_id, c.order_id, c.customer_id, n.pizza_name
  ORDER BY c.record_id, c.order_id
),
SELECT record_id,
     order_id,
     customer_id,
     CASE
       WHEN add_ons IS NOT NULL AND exclude IS NOT NULL
         THEN CONCAT(pizza_name, ': Extra ', add_ons, ' / Exclude ', exclude)
       WHEN add_ons IS NOT NULL AND exclude IS NULL
         THEN CONCAT(pizza_name, ': Extra ', add_ons)
       WHEN exclude IS NOT NULL AND add_ons IS NULL
         THEN CONCAT(pizza_name, ': Exclude ', exclude)
       ELSE pizza_name
     END AS item_record
FROM cte;

/*5.  Generate an alphabetically ordered comma separated ingredient list for each pizza order from 
the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"*/

WITH cte AS ( --CTE for excluded items from pizza
    SELECT c.record_id,
           c.order_id,
           c.customer_id,
           n.pizza_name,
           t.topping_name
    FROM cleaned_customer_orders AS c
    JOIN pizza_names AS n ON c.pizza_id = n.pizza_id
    JOIN cleaned_pizza_recipes AS r ON c.pizza_id = r.pizza_id
    JOIN pizza_toppings AS t ON r.topping_id = t.topping_id
    WHERE c.exclusion_id IS DISTINCT FROM t.topping_id
),
cte1 AS ( --CTE for added toppings on pizza
    SELECT c.record_id,
           c.order_id,
           c.customer_id,
           n.pizza_name,
           t.topping_name
    FROM cleaned_customer_orders AS c
    JOIN pizza_names AS n ON c.pizza_id = n.pizza_id
    JOIN pizza_toppings AS t ON c.extra_id = t.topping_id
),
cte2 AS ( --CTE to combine above 2 CTE's
    SELECT *
    FROM cte
    UNION ALL
    SELECT *
    FROM cte1
),
cte3 AS ( --CTE for 2x
    SELECT record_id,
           order_id,
           customer_id,
           pizza_name,
           topping_name,
           CASE
               WHEN COUNT(topping_name) > 1 THEN CONCAT(COUNT(topping_name), 'x', topping_name)
               ELSE topping_name
           END AS pizza_making
    FROM cte2
    GROUP BY record_id, order_id, customer_id, pizza_name, topping_name
)
SELECT record_id,
       order_id,
       customer_id,
       CONCAT(pizza_name, ': ', STRING_AGG(pizza_making, ', ' ORDER BY topping_name)) AS pizza_ingredient
FROM cte3
GROUP BY record_id, order_id, customer_id, pizza_name
ORDER BY record_id;

/*6.  What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?*/

WITH cte AS (--CTE delivered orders
    SELECT c.*
    FROM cleaned_customer_orders AS c
    JOIN runner_orders AS r ON c.order_id = r.order_id
    WHERE r.cancellation IS NULL
),
cte1 AS (--CTE for excluded items from pizza
    SELECT t.topping_name
    FROM cte AS d
    JOIN cleaned_pizza_recipes AS r ON d.pizza_id = r.pizza_id
    JOIN pizza_toppings AS t ON r.topping_id = t.topping_id
    WHERE d.exclusion_id IS DISTINCT FROM t.topping_id
),
cte2 AS (--CTE for added items on pizza
    SELECT t.topping_name
    FROM cte AS d
    JOIN pizza_toppings AS t ON d.extra_id = t.topping_id
),
cte3 AS (--CTE to combine above 2 CTE's
    SELECT *
    FROM cte1
    UNION ALL
    SELECT *
    FROM cte2
)
SELECT topping_name,
       COUNT(topping_name) AS total_quantity
FROM cte3
GROUP BY topping_name
ORDER BY total_quantity DESC, topping_name ASC;