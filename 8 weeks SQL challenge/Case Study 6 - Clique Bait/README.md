<div align="center">

<a href="https://8weeksqlchallenge.com/case-study-6/">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/6.png" alt="Case Study 6 - Clique Bait" width="40%"/>
</a>

# 🦞 Case Study #6 — Clique Bait

### *Digital analytics: user journeys, product funnels and marketing campaigns.*

![Case Study](https://img.shields.io/badge/Case%20Study-%236-FF6B35?style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Digital](https://img.shields.io/badge/Domain-Digital%20Analytics-3498db?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Advanced-c0392b?style=for-the-badge)
![Files](https://img.shields.io/badge/Scripts-3-blueviolet?style=for-the-badge)

[⬅️ Previous: Data Mart](../Case%20Study%205%20-%20Data%20Mart/README.md) &nbsp;•&nbsp; [🏠 Back to Main](../../README.md) &nbsp;•&nbsp; [Next: Balanced Tree Clothing Co. ➡️](../Case%20Study%207%20-%20Balanced%20Tree%20Clothing%20Co/README.md)

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

**Clique Bait** is Danny's online seafood store, and he wants to bring the same data-driven approach to digital that made his other ventures work. The team needs help to:

- 🧭 Understand **how visitors behave** on the site (visits, page views, cart adds, purchases).
- 🔻 Build a **product funnel** to see which products get viewed, added to cart, abandoned or bought.
- 📣 Judge **marketing campaigns** by joining visit data with campaign dates, ad impressions and clicks.

---

## 🧠 What I Did

### 📈 A. Digital Analysis
| # | Question | Approach |
|:-:|---|---|
| 1 | Total users | `COUNT(DISTINCT user_id)` |
| 2 | Average cookies per user | Per-user cookie count in a CTE, then `AVG` |
| 3 | Unique visits per month | `COUNT(DISTINCT visit_id)` grouped by `EXTRACT(MONTH …)` |
| 4 | Events per event type | `LEFT JOIN event_identifier` |
| 5 | % of visits with a purchase | Distinct purchase visits ÷ all distinct visits |
| 6 | % of visits that reach checkout but do not purchase | Per-visit flags (`page_id = 12`, `event_type = 3`) in a CTE |
| 7 | Top pages by views | Join to `page_hierarchy`, filter on `Page View` |
| 8 | Views and cart adds per product category | Conditional `SUM(CASE …)` |
| 9 | Top products by purchases | CTE of purchasing visits joined back to cart-add events |

### 🔻 B. Product Funnel Analysis
Created two reusable **views**:

| View | What it contains |
|---|---|
| `product_summary_view` | Per product: views, cart adds, **abandoned** (added but visit had no purchase) and purchased |
| `category_summary_view` | The same metrics rolled up per product category |

Then answered from those views:

| # | Question | Approach |
|:-:|---|---|
| 1 | Product with most views, cart adds, purchases | `ORDER BY … DESC LIMIT 1` for each metric |
| 2 | Product most likely to be abandoned | Highest `abandoned` count |
| 3 | Highest view-to-purchase percentage | `purchased_product / product_views` |
| 4 | Average view → cart-add conversion | `SUM(added_to_cart) / SUM(product_views)` |
| 5 | Average cart-add → purchase conversion | `SUM(purchased_product) / SUM(added_to_cart)` |

### 📣 C. Campaigns Analysis
Built **one row per `visit_id`** with:

`user_id` · `visit_id` · `visit_start_time` · `page_views` · `cart_adds` · `purchase` (1/0 flag) · `campaign_name` · `impression` · `click` · `cart_products`

Key technique: each visit is matched to a campaign when `visit_start_time BETWEEN start_date AND end_date`, and `cart_products` is a comma-separated list of items in the **order they were added** using `STRING_AGG(… ORDER BY sequence_number)`.

> The file also contains the open-ended campaign-insights brief (uplift for users who clicked vs. only saw an impression vs. saw none) as an extension task. The visit-level table above is the dataset that analysis is built on.

---

## 🛠️ SQL Skills Demonstrated

![Views](https://img.shields.io/badge/Views-✔-success?style=flat-square)
![Funnel](https://img.shields.io/badge/Funnel%20Analysis-✔-success?style=flat-square)
![StringAgg](https://img.shields.io/badge/STRING__AGG%20with%20ORDER%20BY-✔-success?style=flat-square)
![RangeJoin](https://img.shields.io/badge/Range%20Joins%20(BETWEEN)-✔-success?style=flat-square)
![Cond](https://img.shields.io/badge/Conditional%20Aggregation-✔-success?style=flat-square)
![CTE](https://img.shields.io/badge/Multi--CTE%20Queries-✔-success?style=flat-square)
![Conv](https://img.shields.io/badge/Conversion%20Rates-✔-success?style=flat-square)

---

## 💻 Code Spotlight

**Product funnel view: views, cart adds, abandoned and purchased**

```sql
CREATE VIEW product_summary_view AS
WITH cte AS (
    SELECT visit_id,
           SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase_visits
    FROM events
    GROUP BY visit_id
)
SELECT p.product_id,
       p.page_name AS product_name,
       p.product_category,
       SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS product_views,
       SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS added_to_cart,
       SUM(CASE WHEN event_type = 2 AND c.purchase_visits = 0 THEN 1 ELSE 0 END) AS abandoned,
       SUM(CASE WHEN event_type = 2 AND c.purchase_visits = 1 THEN 1 ELSE 0 END) AS purchased_product
FROM events AS e
JOIN page_hierarchy AS p ON p.page_id = e.page_id
JOIN cte AS c ON c.visit_id = e.visit_id
WHERE p.product_id IS NOT NULL
GROUP BY p.product_id, p.page_name, p.product_category
ORDER BY p.product_id;
```

**Cart contents in the order items were added**

```sql
SELECT e.visit_id,
       STRING_AGG(p.page_name, ', ' ORDER BY e.sequence_number) AS cart_products
FROM events AS e
JOIN page_hierarchy AS p ON e.page_id = p.page_id
WHERE e.event_type = 2
GROUP BY e.visit_id;
```

---

## 📂 Files in This Folder

| File | Description |
|---|---|
| [📄 `Dataset.sql`](./Dataset.sql) | Creates the schema and tables, inserts all event data |
| [📈 `A. Digital Analysis.sql`](./A.%20Digital%20Analysis.sql) | 9 questions on users, visits, events and top pages/products |
| [🔻 `B. Product Funnel Analysis.sql`](./B.%20Product%20Funnel%20Analysis.sql) | Two summary views (product and category) plus 5 funnel questions |
| [📣 `C. Campaigns Analysis.sql`](./C.%20Campaigns%20Analysis.sql) | One-row-per-visit table with campaign mapping, impressions and clicks |

---

## 📬 Contact Me

<p align="center">
  <a href="https://www.linkedin.com/in/ayush-jena/"><img src="https://img.shields.io/badge/LinkedIn-Ayush%20Jena-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"/></a>
  <a href="mailto:ayushjena227@gmail.com"><img src="https://img.shields.io/badge/Email-ayushjena227%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/></a>
  <a href="https://github.com/ayushjena1"><img src="https://img.shields.io/badge/GitHub-ayushjena1-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/></a>
</p>

<p align="center">⭐ If you found this helpful, consider giving the repo a star! ⭐</p>
