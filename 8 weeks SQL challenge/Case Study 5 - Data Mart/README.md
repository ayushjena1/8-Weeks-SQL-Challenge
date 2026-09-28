<div align="center">

<a href="https://8weeksqlchallenge.com/case-study-5/">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/5.png" alt="Case Study 5 - Data Mart" width=40%"/>
</a>

# 🛒 Case Study #5 — Data Mart

### *Did sustainable packaging help or hurt sales? A before-and-after analysis.*

![Case Study](https://img.shields.io/badge/Case%20Study-%235-FF6B35?style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Retail](https://img.shields.io/badge/Domain-Retail%20%26%20E--commerce-e67e22?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Intermediate-f39c12?style=for-the-badge)
![Files](https://img.shields.io/badge/Scripts-4-blueviolet?style=for-the-badge)

[⬅️ Previous: Data Bank](../data_bank/README.md) &nbsp;•&nbsp; [⬅️ Back to Main](../README.md) &nbsp;•&nbsp; [Next: Clique Bait ➡️](../clique_bait/README.md)

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

**Data Mart** is Danny's online supermarket specialising in fresh produce. In **June 2020**, Data Mart made a large-scale supply change: all products moved to **sustainable packaging** at every stage of the supply chain.

Danny needs to quantify the impact:
- 📉 **What was the impact on sales** in the weeks after the change?
- 🔍 **Which areas** of the business (region, platform, age band, demographic, customer type) were affected most?
- 🔮 **What should be done differently** for future sustainability changes?

A single table, `weekly_sales`, holds weekly sales by region, platform (Retail / Shopify), customer type and demographic segment, with `transactions` and `sales` values. The raw table stores dates as text (`DD/MM/YY`) and uses the string `'null'` for missing segments.

---

## 🧠 What I Did

### 🧼 A. Data Cleansing
In **one `CREATE TABLE AS` query** I produced `clean_weekly_sales` with:

| Change | Method |
|---|---|
| `week_date` converted to a real `DATE` | `TO_DATE(week_date, 'DD/MM/YY')` |
| New `week_number`, `month_number`, `calendar_year` columns | `EXTRACT(WEEK / MONTH / YEAR …)` |
| New `age_band` (Young Adults / Middle Aged / Retirees) | `CASE` on the number in `segment` |
| New `demographic` (Couples / Families) | `CASE` on the letter in `segment` |
| `'null'` values replaced with `Unknown` | `CASE` in `segment`, `age_band`, `demographic` |
| New `avg_transaction` | `ROUND(sales::NUMERIC / transactions, 2)` |

### 🔎 B. Data Exploration
| # | Question | Approach |
|:-:|---|---|
| 1 | Which weekday is used for every `week_date`? | `DISTINCT TO_CHAR(week_date, 'Day')` |
| 2 | Which week numbers are missing? | `MIN` / `MAX` week number (data covers weeks **13 to 36**) |
| 3 | Total transactions per year | `SUM` grouped by `calendar_year` |
| 4 | Total sales per region per month | Two-level `GROUP BY` |
| 5 | Transactions per platform | `SUM` grouped by platform |
| 6 | Retail vs Shopify % of sales each month | `SUM(CASE …) / SUM(sales)` |
| 7 | Sales % by demographic each year | CTE + `SUM() OVER (PARTITION BY year)` (plus a `CASE` alternative) |
| 8 | Age band and demographic contributing most to Retail | Share of Retail sales via subquery |
| 9 | Can `avg_transaction` be averaged across rows? | Compared `AVG(avg_transaction)` with `SUM(sales) / SUM(transactions)` |

### ⏱️ C. Before & After Analysis
Taking **2020-06-15 (week 25)** as the baseline:

| # | Question | Approach |
|:-:|---|---|
| 1 | 4 weeks before vs after: change in sales and % | Conditional `SUM` for weeks 21–24 vs 25–28 |
| 2 | 12 weeks before vs after | Same logic for weeks 13–24 vs 25–36 |
| 3 | Compare with 2018 and 2019 | Same windows grouped by `calendar_year` |

### 🎁 D. Bonus: Where Was the Biggest Negative Impact?
Ran the 12-week before/after comparison for 2020 across **five dimensions**: region, platform, age band, demographic and customer type. Each returns sales before, sales after, the difference and the % change.

---

## 🛠️ SQL Skills Demonstrated

![CTAS](https://img.shields.io/badge/CREATE%20TABLE%20AS-✔-success?style=flat-square)
![Dates](https://img.shields.io/badge/Date%20Parsing%20%26%20EXTRACT-✔-success?style=flat-square)
![CASE](https://img.shields.io/badge/Conditional%20Aggregation-✔-success?style=flat-square)
![Window](https://img.shields.io/badge/Window%20Functions-✔-success?style=flat-square)
![Clean](https://img.shields.io/badge/Data%20Cleansing-✔-success?style=flat-square)
![BA](https://img.shields.io/badge/Before%20%26%20After%20Analysis-✔-success?style=flat-square)

---

## 💻 Code Spotlight

**Before-and-after sales comparison**

```sql
WITH cte AS (
    SELECT SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN sales END) AS before_sales,
           SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN sales END) AS after_sales
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
)
SELECT before_sales,
       after_sales,
       after_sales - before_sales AS sales_difference,
       CONCAT(ROUND(100.0 * (after_sales - before_sales) / before_sales, 2), '%') AS percent_difference
FROM cte;
```

**Deriving `age_band` and `demographic` from the `segment` code**

```sql
CASE
  WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
  WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
  WHEN RIGHT(segment, 1) IN ('3', '4') THEN 'Retirees'
  ELSE 'Unknown'
END AS age_band,
CASE
  WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
  WHEN LEFT(segment, 1) = 'F' THEN 'Families'
  ELSE 'Unknown'
END AS demographic
```

---

## 📂 Files in This Folder

| File | Description |
|---|---|
| [📄 `Dataset.sql`](./Dataset.sql) | Creates the schema and `weekly_sales` table, inserts the data |
| [🧼 `A. Data Cleansing Steps.sql`](./A.%20Data%20Cleansing%20Steps.sql) | Builds the `clean_weekly_sales` table in a single query |
| [🔎 `B. Data Exploration.sql`](./B.%20Data%20Exploration.sql) | 9 exploration questions on time, platform and demographics |
| [⏱️ `C. Before & After Analysis.sql`](./C.%20Before%20%26%20After%20Analysis.sql) | Sales impact around the 2020-06-15 packaging change |
| [🎁 `D. Bonus Question.sql`](./D.%20Bonus%20Question.sql) | Which business areas were hit hardest |

---

## 📬 Contact Me

<p align="center">
  <a href="https://www.linkedin.com/in/ayush-jena/"><img src="https://img.shields.io/badge/LinkedIn-Ayush%20Jena-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"/></a>
  <a href="mailto:ayushjena227@gmail.com"><img src="https://img.shields.io/badge/Email-ayushjena227%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/></a>
  <a href="https://github.com/ayushjena1"><img src="https://img.shields.io/badge/GitHub-ayushjena1-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/></a>
</p>

<p align="center">⭐ If you found this helpful, consider giving the repo a star! ⭐</p>
