SELECT * FROM plans
SELECT * FROM subscriptions

------------------------C. Challenge Payment------------------------

/*The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts 
paid by each customer in the subscriptions table with the following requirements:

1. Monthly payments always occur on the same day of month as the original start_date of any monthly
   paid plan
2. Upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month 
   and start immediately
3. Upgrades from pro monthly to pro annual are paid at the end of the current billing period and also 
   starts at the end of the month period
4. Once a customer churns they will no longer make payments*/


WITH payments AS (
  SELECT
    s.customer_id,
    s.plan_id,
    p.plan_name,
    s.start_date,
    p.price AS amount,
    LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan,
    LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_start_date
  FROM subscriptions AS s
  JOIN plans AS p ON p.plan_id = s.plan_id
  WHERE s.plan_id != 0
    AND s.start_date BETWEEN '2020-01-01' AND '2020-12-31'
),
date_bounds AS (
  SELECT
    customer_id,
    plan_id,
    plan_name,
    amount,
    start_date,
    CASE
      -- Active plan with no further changes in 2020
      WHEN next_plan IS NULL AND plan_id != 3 THEN '2020-12-31'::DATE
      -- Upgrades from pro monthly to pro annual end 1 month prior to annual start
      WHEN plan_id = 2 AND next_plan = 'pro annual' THEN (next_start_date - INTERVAL '1 month')::DATE
      -- Upgrades or churn end right when next plan starts (subtract 1 day to prevent double billing on same day)
      WHEN next_plan IN ('churn', 'pro monthly', 'pro annual', 'basic monthly') THEN (next_start_date - INTERVAL '1 day')::DATE
      -- Annual plan is a single payment
      WHEN plan_id = 3 THEN start_date
    END AS end_date
  FROM payments
  WHERE plan_id != 4 -- Exclude churn rows
),
expanded_payments AS (
  SELECT
    customer_id,
    plan_id,
    plan_name,
    GENERATE_SERIES(start_date, end_date, '1 month')::DATE AS payment_date,
    amount
  FROM date_bounds
  WHERE start_date <= end_date
),
lagged_payments AS (
  SELECT
    customer_id,
    plan_id,
    plan_name,
    payment_date,
    amount,
    LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY payment_date) AS prev_plan_id,
    LAG(payment_date) OVER (PARTITION BY customer_id ORDER BY payment_date) AS prev_payment_date,
    LAG(amount) OVER (PARTITION BY customer_id ORDER BY payment_date) AS prev_amount
  FROM expanded_payments
)
SELECT
  customer_id,
  plan_id,
  plan_name,
  payment_date,
  CASE
    -- Discount upgrade payment if upgraded in the same calendar month from a lower tier
    WHEN prev_plan_id IS NOT NULL 
     AND prev_plan_id < plan_id
     AND EXTRACT(MONTH FROM prev_payment_date) = EXTRACT(MONTH FROM payment_date)
     AND EXTRACT(YEAR FROM prev_payment_date) = EXTRACT(YEAR FROM payment_date)
    THEN amount - prev_amount
    ELSE amount
  END AS amount,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date) AS payment_order
FROM lagged_payments
WHERE customer_id IN (1, 2, 13, 15, 16, 18, 19)
ORDER BY customer_id, payment_date;