<div align="center">

<a href="https://8weeksqlchallenge.com/case-study-8/">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/8.png" alt="Case Study 8 - Fresh Segments" width="40%"/>
</a>

# 🎯 Case Study #8 — Fresh Segments

### *Digital marketing analytics: interests, composition, rankings and index values.*

![Case Study](https://img.shields.io/badge/Case%20Study-%238-FF6B35?style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Marketing](https://img.shields.io/badge/Domain-Digital%20Marketing-9b59b6?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Advanced-c0392b?style=for-the-badge)
![Files](https://img.shields.io/badge/Scripts-4-blueviolet?style=for-the-badge)

[⬅️ Previous: Balanced Tree](../balanced_tree/README.md) &nbsp;•&nbsp; [⬅️ Back to Main](../README.md)

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

**Fresh Segments** is Danny's digital marketing agency. It helps businesses analyse trends in **online ad click behaviour** for their customer base.

Clients share their customer lists, and Fresh Segments aggregates **interest metrics** into a single dataset. For each interest and month, the data shows the **composition** (share of the client's customers who interacted with that interest) and its **ranking**.

Danny wants high-level insights about one major client's customer list and its interests:
- 🧹 Is the data clean enough to trust?
- 📅 Which interests are consistently present, and which are noise?
- 📊 Which interests are strongest, and which are most volatile?
- 🧮 How does the `index_value` reveal each month's leading interests?

---

## 🧠 What I Did

### 🧼 A. Data Exploration and Cleansing
| # | Question | Approach |
|:-:|---|---|
| 1 | Convert `month_year` to a `DATE` | `ALTER TABLE … ALTER COLUMN … TYPE DATE USING TO_DATE(month_year, 'MM-YYYY')` |
| 2 | Record count per month (NULLs first) | `GROUP BY month_year ORDER BY month_year NULLS FIRST` |
| 3 | What to do with NULLs | Found that they were rows with no `interest_id` or `month_year` (empty logging entries), so I `DELETE`d them |
| 4 | IDs in one table but not the other | `NOT IN` subqueries in both directions |
| 5 | Summarise `interest_map` IDs | `COUNT(id)` vs `COUNT(DISTINCT id)` |
| 6 | Best join type (checked with `interest_id = 21246`) | `LEFT JOIN` from metrics to map |
| 7 | Any `month_year` before `created_at`? | Found 188 records, then re-checked at month level to confirm they are valid |

### 🔍 B. Interest Analysis
| # | Question | Approach |
|:-:|---|---|
| 1 | Interests present in all months | Compare each interest's distinct months with the total (14) |
| 2 | Cumulative % of interests by months present | Window `SUM() OVER (ORDER BY total_months DESC)` ÷ grand total |
| 3 | Data points removed if we drop rare interests | Count rows for interests present in fewer than 6 months |
| 4 | Does that decision make sense commercially? | Written business argument (in the file's comments) |
| 5 | Unique interests per month after filtering | `HAVING COUNT(DISTINCT month_year) >= 6` then group by month |

### 📊 C. Segment Analysis
| # | Question | Approach |
|:-:|---|---|
| 1 | Top 10 and bottom 10 interests by max composition | `ROW_NUMBER()` to keep each interest's peak month, then `UNION ALL` of two `LIMIT 10` sets |
| 2 | 5 interests with lowest average ranking | `AVG(ranking)` sorted ascending |
| 3 | 5 interests with the highest standard deviation of `percentile_ranking` | `STDDEV()` on the filtered interests |
| 4 | Min and max `percentile_ranking` (with month) for those 5 | Two `ROW_NUMBER()` ranks (ascending and descending) pivoted with `MAX(CASE …)` |
| 5 | Describe the customers and what to show or avoid | Written recommendation (in the file's comments) |

### 📐 D. Index Analysis
| # | Question | Approach |
|:-:|---|---|
| 1 | Top 10 interests by average composition each month | `DENSE_RANK() OVER (PARTITION BY month_year ORDER BY composition / index_value DESC)` |
| 2 | Which interest appears most often in those top 10s | `COUNT(*)` of rank ≤ 10 rows |
| 3 | Average of the top-10 average compositions per month | `AVG` over rank ≤ 10 |
| 4 | 3-month rolling average of the max composition (Sep 2018 – Aug 2019) with the previous two leaders | `AVG() OVER (… ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` plus `LAG()` for the "1 month ago" and "2 months ago" columns |
| 5 | Why might the max composition change month to month? | Written business reasoning (in the file's comments) |

---

## 🛠️ SQL Skills Demonstrated

![Window](https://img.shields.io/badge/Rolling%20Averages-✔-success?style=flat-square)
![LagLead](https://img.shields.io/badge/LAG-✔-success?style=flat-square)
![Rank](https://img.shields.io/badge/ROW__NUMBER%20%26%20DENSE__RANK-✔-success?style=flat-square)
![Stats](https://img.shields.io/badge/STDDEV%20%26%20Cumulative%20%25-✔-success?style=flat-square)
![Clean](https://img.shields.io/badge/Data%20Cleansing%20%26%20Validation-✔-success?style=flat-square)
![Pivot](https://img.shields.io/badge/Conditional%20Pivoting-✔-success?style=flat-square)
![Cast](https://img.shields.io/badge/Type%20Casting-✔-success?style=flat-square)

---

## 💻 Code Spotlight

**3-month rolling average with the previous months' leaders**

```sql
cte3 AS (
    SELECT month_year,
           interest_name,
           max_composition,
           ROUND(
               AVG(max_composition) OVER (
                   ORDER BY month_year
                   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
               )::NUMERIC,
               2
           ) AS "3_month_moving_avg",
           LAG(interest_name, 1) OVER (ORDER BY month_year) || ': ' ||
           LAG(max_composition, 1) OVER (ORDER BY month_year) AS "1_month_ago",
           LAG(interest_name, 2) OVER (ORDER BY month_year) || ': ' ||
           LAG(max_composition, 2) OVER (ORDER BY month_year) AS "2_months_ago"
    FROM cte2
)
```

**Cleaning the date column**

```sql
ALTER TABLE fresh_segments.interest_metrics
  ALTER COLUMN month_year TYPE DATE USING TO_DATE(month_year, 'MM-YYYY');
```

---

## 📂 Files in This Folder

| File | Description |
|---|---|
| [📄 `Dataset.sql`](./Dataset.sql) | Creates the schema and tables, inserts the metrics and mapping data |
| [🧼 `A. Data Exploration and Cleansing.sql`](./A.%20Data%20Exploration%20and%20Cleansing.sql) | 7 questions on date types, NULLs, joins and data validity |
| [🔍 `B. Interest Analysis.sql`](./B.%20Interest%20Analysis.sql) | 5 questions on interest coverage across months |
| [📊 `C. Segment Analysis.sql`](./C.%20Segment%20Analysis.sql) | 5 questions on top/bottom interests, rankings and volatility |
| [📐 `D. Index Analysis.sql`](./D.%20Index%20Analysis.sql) | 5 questions on average composition and a 3-month rolling average |

---

## 📬 Contact Me

<p align="center">
  <a href="https://www.linkedin.com/in/ayush-jena/"><img src="https://img.shields.io/badge/LinkedIn-Ayush%20Jena-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"/></a>
  <a href="mailto:ayushjena227@gmail.com"><img src="https://img.shields.io/badge/Email-ayushjena227%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/></a>
  <a href="https://github.com/ayushjena1"><img src="https://img.shields.io/badge/GitHub-ayushjena1-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/></a>
</p>

<p align="center">⭐ If you found this helpful, consider giving the repo a star! ⭐</p>
