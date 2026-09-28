ALTER USER postgres SET search_path TO pizza_runner, public;
SET search_path = pizza_runner;

SELECT *
FROM customer_orders

SELECT *
FROM pizza_names

SELECT *
FROM pizza_recipes

SELECT *
FROM pizza_toppings

SELECT *
FROM runner_orders

SELECT *
FROM runners

------------------------Data CLeaning------------------------

--Handling the 'null' and blanks for customer_orders columns(exclusions and extras)

UPDATE pizza_runner.customer_orders
SET exclusions = CASE
        WHEN exclusions IN ('null', '') THEN NULL
        ELSE exclusions
    END,
    extras = CASE
        WHEN extras IN ('null', '') THEN NULL
        ELSE extras
    END;

--Handling the 'km' and 'null' for runner_orders column(distance, pickup_time and cancellation)

UPDATE pizza_runner.runner_orders
SET distance = CASE
    WHEN distance IN ('null', '') THEN NULL
    ELSE TRIM(REPLACE(distance, 'km', ''))
END;

UPDATE pizza_runner.runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null';

UPDATE pizza_runner.runner_orders
SET cancellation = NULL
WHERE cancellation IN ('null', '');

--Extracting numbers from duration and handling 'null' to NULL for runner_orders column(duration)

UPDATE pizza_runner.runner_orders
SET duration = CASE
    WHEN duration IN ('null', '') THEN NULL
    ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g')
END;

--Converting data types

ALTER TABLE pizza_runner.runner_orders
  ALTER COLUMN distance TYPE NUMERIC USING distance::NUMERIC,
  ALTER COLUMN duration TYPE INTEGER USING duration::INTEGER,
  ALTER COLUMN pickup_time TYPE TIMESTAMP USING pickup_time::TIMESTAMP;

--Created a VIEW for separating and extracting the toppings for pizza_recipes column(toppings) 

CREATE OR REPLACE VIEW pizza_runner.cleaned_pizza_recipes AS
SELECT pizza_id,
       CAST(UNNEST(string_to_array(toppings, ',')) AS INT) AS topping_id
FROM pizza_runner.pizza_recipes;

--Created a VIEW for extracting the id's of exclusions and extras for customer_orders column(extras, exclusions)

CREATE OR REPLACE VIEW pizza_runner.cleaned_customer_orders AS
SELECT c.record_id,
     c.order_id,
     c.customer_id,
     c.pizza_id,
     CAST(n.exclusion_id AS INT) AS exclusion_id,
     CAST(n.extra_id AS INT) AS extra_id,
     c.order_time
FROM (
  SELECT ROW_NUMBER() OVER () AS record_id,
       order_id,
       customer_id,
       pizza_id,
       string_to_array(exclusions, ',') AS exclusion_array,
       string_to_array(extras, ',') AS extra_array,
       order_time
  FROM pizza_runner.customer_orders
) AS c
LEFT JOIN LATERAL UNNEST(c.exclusion_array, c.extra_array) AS n(exclusion_id, extra_id)
  ON TRUE;
