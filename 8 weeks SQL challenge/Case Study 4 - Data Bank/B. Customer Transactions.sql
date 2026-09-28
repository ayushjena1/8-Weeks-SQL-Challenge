SELECT *
FROM regions

SELECT *
FROM customer_nodes

SELECT *
FROM customer_transactions

------------------------B. Customer Transactions------------------------

/*1.  What is the unique count and total amount for each transaction type?*/

SELECT txn_type,
       COUNT(txn_type),
       SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY DISTINCT txn_type
ORDER BY total_amount DESC;

/*2.  What is the average total historical deposit counts and amounts for all customers?*/

WITH cte AS (
    SELECT customer_id,
           COUNT(txn_type) AS deposit_counts,
           SUM(txn_amount) AS total_historical_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT ROUND(AVG(deposit_counts)),
       ROUND(AVG(total_historical_amount))
FROM cte;

/*3.  For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase 
or 1 withdrawal in a single month?*/

WITH cte AS (
        SELECT EXTRACT(MONTH FROM txn_date) AS txn_month,
                     customer_id,
                     SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
                     SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
                     SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM customer_transactions
    GROUP BY customer_id, EXTRACT(MONTH FROM txn_date)
)
SELECT txn_month,
             COUNT(customer_id) AS customer_counts
FROM cte
WHERE deposit_count > 1
    AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY txn_month
ORDER BY txn_month;

/*4.  What is the closing balance for each customer at the end of the month?*/

WITH cte AS (
    SELECT customer_id,
           DATE_TRUNC('month', txn_date) AS txn_month,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS opening_balance
    FROM customer_transactions
    GROUP BY customer_id, DATE_TRUNC('month', txn_date)
)
SELECT customer_id,
       TO_CHAR(txn_month, 'YYYY-MM') AS txn_monthly,
       opening_balance,
       SUM(opening_balance) OVER (
           PARTITION BY customer_id
           ORDER BY txn_month
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS closing_balance
FROM cte
ORDER BY customer_id, txn_month;

/*5.  What is the percentage of customers who increase their closing balance by more than 5%?*/

WITH cte AS (
    SELECT customer_id,
           DATE_TRUNC('month', txn_date) AS txn_month,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS opening_balance
    FROM customer_transactions
    GROUP BY customer_id, DATE_TRUNC('month', txn_date)
),
cte1 AS (
    SELECT customer_id,
           txn_month,
           SUM(opening_balance) OVER (
               PARTITION BY customer_id
               ORDER BY txn_month
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS closing_balance
    FROM cte
),
cte2 AS (
    SELECT DISTINCT ON (customer_id)
           customer_id,
           FIRST_VALUE(closing_balance) OVER (
               PARTITION BY customer_id
               ORDER BY txn_month
           ) AS start_balance,
           LAST_VALUE(closing_balance) OVER (
               PARTITION BY customer_id
               ORDER BY txn_month
               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
           ) AS end_balance
    FROM cte1
)
SELECT
       CONCAT(
           ROUND(
               100.0 * COUNT(CASE WHEN end_balance > start_balance * 1.05 THEN 1 END) /
               COUNT(*)
           ),
           '%'
       ) AS increased_percentage
FROM cte2;