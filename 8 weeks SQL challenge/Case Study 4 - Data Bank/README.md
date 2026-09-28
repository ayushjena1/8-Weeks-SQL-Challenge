<div align="center">

<a href="https://8weeksqlchallenge.com/case-study-4/">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/4.png" alt="Case Study 4 - Data Bank" width="40%"/>
</a>

# 🏦 Case Study #4 — Data Bank

### *Digital banking meets data storage: nodes, transactions and balances.*

![Case Study](https://img.shields.io/badge/Case%20Study-%234-FF6B35?style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Finance](https://img.shields.io/badge/Domain-Banking%20%26%20Finance-16a085?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Intermediate-f39c12?style=for-the-badge)
![Files](https://img.shields.io/badge/Scripts-2-blueviolet?style=for-the-badge)

[⬅️ Previous: Foodie Fi](../Case%20Study%203%20-%20Foodie%20Fi/README.md) &nbsp;•&nbsp; [🏠 Back to Main](../../README.md) &nbsp;•&nbsp; [Next: Data Mart ➡️](../Case%20Study%205%20-%20Data%20Mart/README.md)

</div>

---

## 📑 Table of Contents
- [🎯 Business Problem](#-business-problem)
- [🧠 What I Did](#-what-i-did)
- [🛠️ SQL Skills Demonstrated](#️-sql-skills-demonstrated)
- [💻 Code Spotlight](#-code-spotlight)
- [📂 Files in This Folder](#-files-in-this-folder)
- [📬 Contact Me](#-contact-me)

---

## 🎯 Business Problem

**Data Bank** is a new digital-only neo-bank that combines banking with **secure distributed data storage**. Customers are allocated cloud storage that is linked to their account balance, so the business needs to understand how customers are spread across the network and how their money behaves.

Danny needs help with two things:
- 🗺️ **Where** are customers allocated, and how often are they moved between nodes?
- 💸 **What** are customers doing with their money (deposits, purchases, withdrawals), and how do balances change month to month?

> 📝 An `end_date` of `9999-12-31` means the customer is still on that node, so I excluded it when calculating reallocation times.

---

## 🧠 What I Did

### 🗺️ A. Customer Nodes Exploration
| # | Question | Approach |
|:-:|---|---|
| 1 | Unique nodes in the system | `COUNT(DISTINCT node_id)` |
| 2 | Nodes per region | Join to `regions`, `COUNT(DISTINCT node_id)` per region |
| 3 | Customers per region | `COUNT(DISTINCT customer_id)` per region |
| 4 | Average days before a customer is reallocated | `AVG(end_date - start_date)` excluding the `9999-12-31` placeholder |
| 5 | Median, 80th and 95th percentile of reallocation days per region | `PERCENTILE_CONT(…) WITHIN GROUP (ORDER BY …)` |

### 💳 B. Customer Transactions
| # | Question | Approach |
|:-:|---|---|
| 1 | Count and total amount per transaction type | `GROUP BY txn_type` |
| 2 | Average historical deposit count and amount per customer | Per-customer CTE, then `AVG` |
| 3 | Customers per month with 2+ deposits and 1 purchase **or** 1 withdrawal | Monthly conditional counts, then filter |
| 4 | Closing balance for each customer at each month end | Signed monthly net + running `SUM() OVER (ORDER BY month ROWS UNBOUNDED PRECEDING)` |
| 5 | % of customers whose closing balance grew by more than 5% | `FIRST_VALUE` / `LAST_VALUE` window functions comparing first and last balance |

---

## 🛠️ SQL Skills Demonstrated

![Percentile](https://img.shields.io/badge/PERCENTILE__CONT-✔-success?style=flat-square)
![Running](https://img.shields.io/badge/Running%20Totals-✔-success?style=flat-square)
![Window](https://img.shields.io/badge/FIRST__VALUE%20%26%20LAST__VALUE-✔-success?style=flat-square)
![DateTrunc](https://img.shields.io/badge/DATE__TRUNC-✔-success?style=flat-square)
![CTE](https://img.shields.io/badge/CTEs-✔-success?style=flat-square)
![Cond](https://img.shields.io/badge/Conditional%20Aggregation-✔-success?style=flat-square)

---

## 💻 Code Spotlight

**Month-end closing balance with a running total**

```sql
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
```

**Percentiles per region**

```sql
SELECT region_id,
       region_name,
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY duration) AS median,
       PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY duration) AS percentile_80th,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration) AS percentile_95th
FROM cte
GROUP BY region_id, region_name
ORDER BY region_id;
```

---

## 📂 Files in This Folder

| File | Description |
|---|---|
| [📄 `Dataset.sql`](./Dataset.sql) | Creates the schema and tables, inserts the data |
| [🗺️ `A. Customer Nodes Exploration.sql`](./A.%20Customer%20Nodes%20Exploration.sql) | 5 questions on nodes, regions and reallocation days |
| [💳 `B. Customer Transactions.sql`](./B.%20Customer%20Transactions.sql) | 5 questions on transactions, balances and growth |

---

## 📬 Contact Me

<p align="center">
  <a href="https://www.linkedin.com/in/ayush-jena/"><img src="https://img.shields.io/badge/LinkedIn-Ayush%20Jena-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"/></a>
  <a href="mailto:ayushjena227@gmail.com"><img src="https://img.shields.io/badge/Email-ayushjena227%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/></a>
  <a href="https://github.com/ayushjena1"><img src="https://img.shields.io/badge/GitHub-ayushjena1-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/></a>
</p>

<p align="center">⭐ If you found this helpful, consider giving the repo a star! ⭐</p>
