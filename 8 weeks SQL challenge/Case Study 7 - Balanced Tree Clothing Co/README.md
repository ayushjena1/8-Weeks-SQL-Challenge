<div align="center">

<a href="https://8weeksqlchallenge.com/case-study-7/">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/7.png" alt="Case Study 7 - Balanced Tree Clothing Co." width="40%"/>
</a>

# 👕 Case Study #7 — Balanced Tree Clothing Co.

### *Sales performance, transactions and product insights for a fashion retailer.*

![Case Study](https://img.shields.io/badge/Case%20Study-%237-FF6B35?style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Fashion](https://img.shields.io/badge/Domain-Fashion%20Retail-e84393?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Intermediate-f39c12?style=for-the-badge)
![Files](https://img.shields.io/badge/Scripts-4-blueviolet?style=for-the-badge)

[⬅️ Previous: Clique Bait](../clique_bait/README.md) &nbsp;•&nbsp; [⬅️ Back to Main](../README.md) &nbsp;•&nbsp; [Next: Fresh Segments ➡️](../fresh_segments/README.md)

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

**Balanced Tree Clothing Company** offers an optimised range of clothing and lifestyle wear for the modern adventurer. Danny, the CEO, wants help from the data team to:

- 📊 Analyse **sales performance** (quantity, revenue and discounts).
- 🧾 Understand **transactions** (basket size, revenue per transaction, members vs. non-members).
- 👗 Explore **product, segment and category** performance.
- 📝 Produce a **basic financial report** to share across the business.

---

## 🧠 What I Did

### 💵 A. High Level Sales Analysis
| # | Question | Approach |
|:-:|---|---|
| 1 | Total quantity sold | `SUM(qty)` per product |
| 2 | Revenue before discounts | `SUM(qty * price)` |
| 3 | Total discount amount | `SUM(qty * price * discount / 100.0)` |

### 🧾 B. Transaction Analysis
| # | Question | Approach |
|:-:|---|---|
| 1 | Unique transactions | `COUNT(DISTINCT txn_id)` |
| 2 | Average unique products per transaction | Per-transaction CTE, then `AVG` |
| 3 | 25th / 50th / 75th percentile of revenue per transaction | `PERCENTILE_CONT` |
| 4 | Average discount per transaction | Per-transaction discount CTE, then `AVG` |
| 5 | Members vs. non-members split | Distinct `txn_id` + `member` with conditional `SUM(CASE …)` |
| 6 | Average revenue: members vs. non-members | `SUM(qty * price) / COUNT(DISTINCT txn_id)` (plus a CTE alternative) |

### 👗 C. Product Analysis
| # | Question | Approach |
|:-:|---|---|
| 1 | Top products by revenue before discount | `SUM(qty * price)` sorted descending |
| 2 | Quantity, revenue and discount per **segment** | Join `product_details`, group by segment |
| 3 | Top-selling product per segment | `DENSE_RANK()` partitioned by segment |
| 4 | Quantity, revenue and discount per **category** | Same pattern grouped by category |
| 5 | Top-selling product per category | `DENSE_RANK()` partitioned by category |
| 6 | Revenue split by product within each segment | `SUM() OVER (PARTITION BY segment_id)` |
| 7 | Revenue split by segment within each category | `SUM() OVER (PARTITION BY category_name)` |
| 8 | Revenue split by category | `SUM() OVER ()` for the grand total |
| 9 | Transaction **penetration** per product | Distinct transactions containing the product ÷ all transactions |
| 10 | Most common combination of 3 products in one transaction | Self-join `sales` three times with `prod_id` ordering to avoid duplicate combos |

### 🎁 D. Bonus Challenge
Reconstructed the `product_details` table from `product_hierarchy` and `product_prices` using a **triple self-join** on the hierarchy (style → segment → category).

---

## 🛠️ SQL Skills Demonstrated

![SelfJoin](https://img.shields.io/badge/Self%20Joins-✔-success?style=flat-square)
![Window](https://img.shields.io/badge/DENSE__RANK%20%26%20SUM%20OVER-✔-success?style=flat-square)
![Percentile](https://img.shields.io/badge/PERCENTILE__CONT-✔-success?style=flat-square)
![Hierarchy](https://img.shields.io/badge/Hierarchical%20Data-✔-success?style=flat-square)
![Basket](https://img.shields.io/badge/Basket%20%26%20Combination%20Analysis-✔-success?style=flat-square)
![Pct](https://img.shields.io/badge/Percent--of--Total-✔-success?style=flat-square)

---

## 💻 Code Spotlight

**Most common 3-product combination in a single transaction**

```sql
WITH cte AS (
    SELECT s1.prod_id AS product_1,
           s2.prod_id AS product_2,
           s3.prod_id AS product_3
    FROM sales AS s1
    JOIN sales AS s2 ON s1.txn_id = s2.txn_id AND s1.prod_id < s2.prod_id
    JOIN sales AS s3 ON s1.txn_id = s3.txn_id AND s2.prod_id < s3.prod_id
)
SELECT pd1.product_name AS product_1,
       pd2.product_name AS product_2,
       pd3.product_name AS product_3,
       COUNT(*) AS combination_count
FROM cte
JOIN product_details AS pd1 ON cte.product_1 = pd1.product_id
JOIN product_details AS pd2 ON cte.product_2 = pd2.product_id
JOIN product_details AS pd3 ON cte.product_3 = pd3.product_id
GROUP BY pd1.product_name, pd2.product_name, pd3.product_name
ORDER BY combination_count DESC;
```

**Rebuilding `product_details` from the hierarchy**

```sql
SELECT pp.product_id,
       pp.price,
       CONCAT(ph1.level_text, ' ', ph2.level_text, ' - ', ph3.level_text) AS product_name,
       ph3.id AS category_id,
       ph2.id AS segment_id,
       ph1.id AS style_id,
       ph3.level_text AS category_name,
       ph2.level_text AS segment_name,
       ph1.level_text AS style_name
FROM product_hierarchy AS ph1
JOIN product_hierarchy AS ph2 ON ph1.parent_id = ph2.id
JOIN product_hierarchy AS ph3 ON ph2.parent_id = ph3.id
JOIN product_prices AS pp ON ph1.id = pp.id;
```

---

## 📂 Files in This Folder

| File | Description |
|---|---|
| [📄 `Dataset.sql`](./Dataset.sql) | Creates the schema and tables, inserts all sales data |
| [💵 `A. High Level Sales Analysis.sql`](./A.%20High%20Level%20Sales%20Analysis.sql) | Quantity, revenue and discount per product |
| [🧾 `B. Transaction Analysis.sql`](./B.%20Transaction%20Analysis.sql) | 6 questions on basket size, percentiles and membership |
| [👗 `C. Product Analysis.sql`](./C.%20Product%20Analysis.sql) | 10 questions on top products, segments, categories and combinations |
| [🎁 `D. Bonus Challenge.sql`](./D.%20Bonus%20Challenge.sql) | Rebuild `product_details` from the hierarchy and price tables |

---

## 📬 Contact Me

<p align="center">
  <a href="https://www.linkedin.com/in/ayush-jena/"><img src="https://img.shields.io/badge/LinkedIn-Ayush%20Jena-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"/></a>
  <a href="mailto:ayushjena227@gmail.com"><img src="https://img.shields.io/badge/Email-ayushjena227%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/></a>
  <a href="https://github.com/ayushjena1"><img src="https://img.shields.io/badge/GitHub-ayushjena1-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/></a>
</p>

<p align="center">⭐ If you found this helpful, consider giving the repo a star! ⭐</p>
