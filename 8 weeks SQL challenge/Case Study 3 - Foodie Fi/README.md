<div align="center">

<a href="https://8weeksqlchallenge.com/case-study-3/">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png" alt="Case Study 3 - Foodie-Fi" width="40%"/>
</a>

# 🥑 Case Study #3 — Foodie-Fi

### *Subscription analytics: journeys, churn and payments.*

![Case Study](https://img.shields.io/badge/Case%20Study-%233-FF6B35?style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Subscription](https://img.shields.io/badge/Domain-Subscription%20Analytics-8e44ad?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Intermediate-f39c12?style=for-the-badge)
![Files](https://img.shields.io/badge/Scripts-3-blueviolet?style=for-the-badge)

[⬅️ Previous: Pizza Runner](../pizza_runner/README.md) &nbsp;•&nbsp; [⬅️ Back to Main](../README.md) &nbsp;•&nbsp; [Next: Data Bank ➡️](../data_bank/README.md)

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

**Foodie-Fi** is a streaming service, like Netflix but with **only food content**. Customers subscribe monthly or annually for unlimited on-demand access to food videos from around the world.

Danny built Foodie-Fi with a data-driven mindset, so every future investment and feature decision should be backed by data. This case study uses **subscription-style data** to answer questions like:

- 👥 How many customers has Foodie-Fi ever had?
- 🚪 How many customers churn, and when?
- ⬆️ How do customers move between plans?
- 💳 What does the payment history look like for each customer?

Every customer begins on a **free 7-day trial** and automatically continues onto the **basic monthly** plan unless they cancel or choose another plan.

---

## 🧠 What I Did

### 🧭 A. Customer Journey
Joined `subscriptions` to `plans` for eight sample customers (1, 14, 28, 90, 137, 180, 421, 503) and wrote a one-line onboarding story for each. For example:
- **Customer 1:** 7-day trial, then automatically converted to *basic monthly*.
- **Customer 28:** 7-day trial, then went straight to *pro annual*.
- **Customer 90:** the full path of trial → basic monthly → pro monthly → pro annual.

### 📊 B. Data Analysis
| # | Question | Approach |
|:-:|---|---|
| 1 | Total customers ever | `COUNT(DISTINCT customer_id)` |
| 2 | Monthly distribution of trial starts | Filter `plan_id = 0`, group by month |
| 3 | Plan events after 2020 | Date filter + `GROUP BY` plan (CTE and non-CTE versions) |
| 4 | Churn count and percentage | Conditional `SUM(CASE …)` ÷ distinct customers |
| 5 | Customers who churned straight after trial | `LEAD()` to see each customer's next plan |
| 6 | Plan breakdown right after the trial | `LEAD()` + percentage of all customers |
| 7 | Plan breakdown on 2020-12-31 | `LEAD(start_date)` and keep rows where the next date is `NULL` (the latest plan) |
| 8 | Upgrades to annual in 2020 | Filter on `pro annual` and year |
| 9 | Average days from joining to annual plan | Two CTEs (trial date, annual date), average of the date difference |
| 10 | Same average in 30-day buckets | Bucket with integer division (`days / 30 + 1`), label as `0-30`, `31-60`, … |
| 11 | Downgrades from pro monthly to basic monthly in 2020 | `LAG()` to look at the previous plan |

### 💳 C. Challenge: Payments Table for 2020
Built a payment schedule that follows Foodie-Fi's billing rules:

1. Monthly payments fall on the **same day of the month** as the plan start.
2. Upgrading from basic to a higher plan **reduces the charge** by what was already paid that month.
3. A **pro monthly → pro annual** upgrade is charged at the **end of the billing period**.
4. After a customer **churns**, no more payments are made.

---

## 🛠️ SQL Skills Demonstrated

![Window](https://img.shields.io/badge/LEAD%20%26%20LAG-✔-success?style=flat-square)
![Series](https://img.shields.io/badge/GENERATE__SERIES-✔-success?style=flat-square)
![Interval](https://img.shields.io/badge/Date%20Intervals-✔-success?style=flat-square)
![CTE](https://img.shields.io/badge/Multi--step%20CTEs-✔-success?style=flat-square)
![Business](https://img.shields.io/badge/Business%20Rules%20in%20SQL-✔-success?style=flat-square)
![Pct](https://img.shields.io/badge/Percentages%20%26%20Rounding-✔-success?style=flat-square)

---

## 💻 Code Spotlight

**Customers who churned straight after their free trial**

```sql
WITH cte AS (
    SELECT s.customer_id,
           p.plan_name,
           LEAD(p.plan_name) OVER (
               PARTITION BY s.customer_id
               ORDER BY p.plan_id
           ) AS next_plan
    FROM subscriptions AS s
    JOIN plans AS p ON p.plan_id = s.plan_id
)
SELECT COUNT(DISTINCT customer_id) AS churned_users
FROM cte
WHERE plan_name = 'trial'
  AND next_plan = 'churn';
```

**Expanding each plan into monthly payment rows**

```sql
expanded_payments AS (
  SELECT customer_id,
         plan_id,
         plan_name,
         GENERATE_SERIES(start_date, end_date, '1 month')::DATE AS payment_date,
         amount
  FROM date_bounds
  WHERE start_date <= end_date
)
```

---

## 📂 Files in This Folder

| File | Description |
|---|---|
| [📄 `Dataset.sql`](./Dataset.sql) | Creates the schema and tables, inserts plans and subscriptions |
| [🧭 `A. Customer Journey.sql`](./A.%20Customer%20Journey.sql) | Written onboarding journey for 8 sample customers |
| [📊 `B. Data Analysis.sql`](./B.%20Data%20Analysis.sql) | 11 questions on growth, churn, plan mix and upgrades |
| [💳 `C. Challenge Payment.sql`](./C.%20Challenge%20Payment.sql) | Builds a 2020 payments schedule with upgrade and churn rules |

---

## 📬 Contact Me

<p align="center">
  <a href="https://www.linkedin.com/in/ayush-jena/"><img src="https://img.shields.io/badge/LinkedIn-Ayush%20Jena-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"/></a>
  <a href="mailto:ayushjena227@gmail.com"><img src="https://img.shields.io/badge/Email-ayushjena227%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/></a>
  <a href="https://github.com/ayushjena1"><img src="https://img.shields.io/badge/GitHub-ayushjena1-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/></a>
</p>

<p align="center">⭐ If you found this helpful, consider giving the repo a star! ⭐</p>
