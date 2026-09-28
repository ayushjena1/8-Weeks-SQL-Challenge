<div align="center">

<a href="https://8weeksqlchallenge.com/case-study-1/">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" alt="Case Study 1 - Danny's Diner" width="40%"/>
</a>

# 🍜 Case Study #1 — Danny's Diner

### *Who visits, what they spend, and what they love to eat.*

![Case Study](https://img.shields.io/badge/Case%20Study-%231-FF6B35?style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Window%20Functions-4479A1?style=for-the-badge&logo=databricks&logoColor=white)
![Level](https://img.shields.io/badge/Level-Beginner-2ea44f?style=for-the-badge)
![Questions](https://img.shields.io/badge/Questions-10%20%2B%202%20Bonus-blueviolet?style=for-the-badge)

[⬅️ Back to Main](../README.md) &nbsp;•&nbsp; [Next: Pizza Runner ➡️](../Case_Study_2_-_Pizza_Runner/README.md)

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

Danny opened a small Japanese restaurant in early 2021 selling his three favourite foods: **sushi, curry and ramen**. The restaurant has collected a little data but has no idea how to use it.

Danny wants to know:
- 🗓️ **How often** do customers visit?
- 💰 **How much** have they spent?
- 🍣 **Which menu items** are their favourites?

The answers will help him decide whether to **expand the customer loyalty program**, and he also needs a few **ready-made datasets** so his team can inspect the data without writing SQL.

---

## 🧠 What I Did

I answered every question with a **single SQL statement**, using CTEs and window functions wherever ties or "first/last" logic came up.

| # | Question | My Approach |
|:-:|---|---|
| 1 | Total amount each customer spent | `INNER JOIN` sales → menu, `SUM(price)`, `GROUP BY customer_id` |
| 2 | Days each customer visited | `COUNT(DISTINCT order_date)` so multiple items on one day count once |
| 3 | First item purchased by each customer | CTE + `ROW_NUMBER()` ordered by `order_date, product_id` to break same-day ties |
| 4 | Most purchased item overall | `COUNT` per product, `ORDER BY … DESC LIMIT 1` |
| 5 | Most popular item per customer | `DENSE_RANK()` over `COUNT(product_id)` so tied favourites are all kept |
| 6 | First item bought after becoming a member | `DENSE_RANK()` on `order_date` where `order_date >= join_date` |
| 7 | Item bought just before becoming a member | `DENSE_RANK()` in **descending** date order where `order_date < join_date` |
| 8 | Total items & spend before membership | `LEFT JOIN` menu + members, filter `order_date < join_date` |
| 9 | Loyalty points (10 pts per $1, sushi 2×) | `CASE` expression on product name inside `SUM()` |
| 10 | January points with a 2× first-week bonus | `CASE` with `BETWEEN join_date AND join_date + 6`, filtered to January |
| 🎁 11 | "Join all the things" table | `CASE` flag showing whether the customer was a member on each order date |
| 🎁 12 | "Rank all the things" | `RANK()` partitioned by customer, returning `NULL` for non-member purchases |

---

## 🛠️ SQL Skills Demonstrated

![CTE](https://img.shields.io/badge/CTEs-✔-success?style=flat-square)
![Window](https://img.shields.io/badge/ROW__NUMBER%20%7C%20RANK%20%7C%20DENSE__RANK-✔-success?style=flat-square)
![Joins](https://img.shields.io/badge/INNER%20%26%20LEFT%20JOINs-✔-success?style=flat-square)
![CASE](https://img.shields.io/badge/CASE%20Logic-✔-success?style=flat-square)
![Agg](https://img.shields.io/badge/Aggregations-✔-success?style=flat-square)

---

## 💻 Code Spotlight

**Q10: Points with a first-week 2× bonus for members**

```sql
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
```

**Q3: First item per customer with `ROW_NUMBER()`**

```sql
WITH first_purchase AS (
    SELECT s.customer_id,
           m.product_name,
           ROW_NUMBER() OVER (
               PARTITION BY s.customer_id
               ORDER BY s.order_date, s.product_id
           ) AS first_purchased_item
    FROM sales AS s
    INNER JOIN menu AS m ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM first_purchase
WHERE first_purchased_item = 1;
```

---

## 📂 Files in This Folder

| File | Description |
|---|---|
| [📄 `Dataset.sql`](./Dataset.sql) | Creates the tables and inserts the sample data |
| [📄 `Dannys Dinner.sql`](./Dannys%20Dinner.sql) | All 10 case study questions + 2 bonus questions |

---

## 📬 Contact Me

<p align="center">
  <a href="https://www.linkedin.com/in/ayush-jena/"><img src="https://img.shields.io/badge/LinkedIn-Ayush%20Jena-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"/></a>
  <a href="mailto:ayushjena227@gmail.com"><img src="https://img.shields.io/badge/Email-ayushjena227%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/></a>
  <a href="https://github.com/ayushjena1"><img src="https://img.shields.io/badge/GitHub-ayushjena1-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/></a>
</p>

<p align="center">⭐ If you found this helpful, consider giving the repo a star! ⭐</p>
