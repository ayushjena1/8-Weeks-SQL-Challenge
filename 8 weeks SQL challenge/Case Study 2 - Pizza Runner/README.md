<div align="center">

<a href="https://8weeksqlchallenge.com/case-study-2/">
  <img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png" alt="Case Study 2 - Pizza Runner" width="40%"/>
</a>

# 🍕 Case Study #2 — Pizza Runner

### *Cleaning messy data and optimising a pizza delivery startup.*

![Case Study](https://img.shields.io/badge/Case%20Study-%232-FF6B35?style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Data Cleaning](https://img.shields.io/badge/Data-Cleaning-e74c3c?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Intermediate-f39c12?style=for-the-badge)
![Files](https://img.shields.io/badge/Scripts-6-blueviolet?style=for-the-badge)

[⬅️ Previous: Danny's Dinner](../Case%20Study%201%20-%20Danny's%20Dinner/README.md) &nbsp;•&nbsp; [🏠 Back to Main](../../README.md) &nbsp;•&nbsp; [Next: Foodie-Fi ➡️](../Case%20Study%203%20-%20Foodie%20Fi/README.md)

</div>

---

## 📑 Table of Contents
- [🎯 Business Problem](#-business-problem)
- [🛠️ SQL Skills Demonstrated](#️-sql-skills-demonstrated)
- [🧹 Data Cleaning & Transformation](#-data-cleaning--transformation)
- [🧠 What I Did (Sections A–E)](#-what-i-did-sections-ae)
- [💻 Code Spotlight](#-code-spotlight)
- [📂 Files in This Folder](#-files-in-this-folder)
- [📬 Contact Me](#-contact-me)

---

## 🎯 Business Problem

Danny is "Uberising" his pizza empire. **Pizza Runner** takes orders through a mobile app, and freelance **runners** deliver fresh pizza from Danny's HQ to customers.

Before Danny can optimise the business, the raw data needs to be **cleaned** and turned into useful metrics:

- 🍕 How many pizzas are ordered, and when?
- 🏃 How fast and reliable are the runners?
- 🧀 Which toppings are added or excluded most?
- 💵 How much money is the business really making?

> ⚠️ The raw data is intentionally messy: `'null'` strings, blank values, `km` / `minutes` text inside numeric columns, and comma-separated ID lists.

---

## 🛠️ SQL Skills Demonstrated

![Cleaning](https://img.shields.io/badge/Data%20Cleaning-✔-success?style=flat-square)
![Regex](https://img.shields.io/badge/REGEXP__REPLACE-✔-success?style=flat-square)
![Views](https://img.shields.io/badge/Views-✔-success?style=flat-square)
![Unnest](https://img.shields.io/badge/UNNEST%20%26%20LATERAL-✔-success?style=flat-square)
![StringAgg](https://img.shields.io/badge/STRING__AGG-✔-success?style=flat-square)
![DDL](https://img.shields.io/badge/DDL%20%26%20DML-✔-success?style=flat-square)
![Dates](https://img.shields.io/badge/Date%20%26%20Time%20Functions-✔-success?style=flat-square)
![CTE](https://img.shields.io/badge/CTEs-✔-success?style=flat-square)

---

## 🧹 Data Cleaning & Transformation

Before answering anything, I cleaned the source tables:

| Problem | Fix |
|---|---|
| `'null'` and blank strings in `exclusions` / `extras` | `UPDATE … CASE WHEN … IN ('null','') THEN NULL` |
| `km` text in `distance` | `TRIM(REPLACE(distance, 'km', ''))` |
| `minutes` / `mins` / `minute` text in `duration` | `REGEXP_REPLACE(duration, '[^0-9]', '', 'g')` |
| Text columns holding numbers and timestamps | `ALTER TABLE … ALTER COLUMN … TYPE … USING` to `NUMERIC`, `INTEGER`, `TIMESTAMP` |
| Comma-separated topping IDs in `pizza_recipes` | View **`cleaned_pizza_recipes`** using `UNNEST(string_to_array(...))` |
| Comma-separated `exclusions` / `extras` in orders | View **`cleaned_customer_orders`** using `LEFT JOIN LATERAL UNNEST(...)` with a generated `record_id` |

---

## 🧠 What I Did (Sections A–E)

### 🍕 A. Pizza Metrics
| # | Question | Approach |
|:-:|---|---|
| 1–2 | Total pizzas and unique orders | `COUNT` vs `COUNT(DISTINCT)` |
| 3–4 | Successful deliveries per runner / pizza type | Join to `runner_orders` and filter `cancellation IS NULL` |
| 5 | Vegetarian vs Meatlovers per customer | Conditional aggregation with `SUM(CASE …)` |
| 6 | Max pizzas in one delivered order | CTE + `MAX()` |
| 7–8 | Pizzas with changes / no changes / both | `CASE` on `exclusions` and `extras` |
| 9–10 | Volume by hour and by weekday | `EXTRACT(HOUR …)`, `TO_CHAR(…, 'Day')` sorted with `EXTRACT(DOW …)` |

### 🏃 B. Runner and Customer Experience
| # | Question | Approach |
|:-:|---|---|
| 1 | Runner sign-ups per week | Week bucket from `(registration_date - '2021-01-01') / 7 + 1` |
| 2 | Avg minutes for runner to reach HQ | Timestamp difference converted to minutes |
| 3 | Do more pizzas mean longer prep? | Group orders by pizza count and compare average prep time |
| 4 | Avg distance per customer / runner | `ROUND(AVG(distance), 2)` |
| 5 | Longest vs shortest delivery time | `MAX(duration) - MIN(duration)` |
| 6 | Average speed per delivery | `distance / (duration / 60.0)` (km/h) |
| 7 | Successful delivery % per runner | `COUNT(pickup_time) / COUNT(order_id)` |

### 🧀 C. Ingredient Optimisation
| # | Question | Approach |
|:-:|---|---|
| 1 | Standard ingredients per pizza | `STRING_AGG(topping_name, ',')` |
| 2–3 | Most common extra / exclusion | Join the cleaned view to `pizza_toppings`, `COUNT`, `LIMIT 1` |
| 4 | Readable order line (`Meat Lovers: Extra Bacon / Exclude Cheese`) | CTE + conditional `CONCAT` |
| 5 | Alphabetical ingredient list with `2x` for doubled toppings | `UNION ALL` of base recipe minus exclusions plus extras, then `COUNT` to spot doubles |
| 6 | Total quantity of each ingredient used in delivered pizzas | Chained CTEs + `UNION ALL` + `GROUP BY` |

### 💰 D. Pricing and Ratings
| # | Question | Approach |
|:-:|---|---|
| 1 | Revenue with Meatlovers $12 / Vegetarian $10 | `SUM(CASE …)` on delivered orders |
| 2 | Revenue with $1 per extra | Base revenue CTE + `COUNT(extra_id)` |
| 3 | Design a **runner ratings** table | `CREATE TABLE` with `SERIAL` key and `CHECK (rating BETWEEN 1 AND 5)`, plus sample `INSERT`s |
| 4 | One combined delivery summary table | Multi-table join: rating, prep time, duration, speed, pizza count |
| 5 | Profit after paying runners $0.30 per km | Revenue CTE minus `SUM(distance * 0.30)` |

### 🎁 E. Bonus
Showed how the schema handles a new **Supreme** pizza with every topping: one `INSERT` into `pizza_names` and one into `pizza_recipes`, with no structural change needed.

---

## 💻 Code Spotlight

**Cleaning messy `distance` and `duration` columns**

```sql
UPDATE pizza_runner.runner_orders
SET distance = CASE
    WHEN distance IN ('null', '') THEN NULL
    ELSE TRIM(REPLACE(distance, 'km', ''))
END;

UPDATE pizza_runner.runner_orders
SET duration = CASE
    WHEN duration IN ('null', '') THEN NULL
    ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g')
END;

ALTER TABLE pizza_runner.runner_orders
  ALTER COLUMN distance TYPE NUMERIC USING distance::NUMERIC,
  ALTER COLUMN duration TYPE INTEGER USING duration::INTEGER,
  ALTER COLUMN pickup_time TYPE TIMESTAMP USING pickup_time::TIMESTAMP;
```

**Splitting comma-separated toppings into rows**

```sql
CREATE OR REPLACE VIEW pizza_runner.cleaned_pizza_recipes AS
SELECT pizza_id,
       CAST(UNNEST(string_to_array(toppings, ',')) AS INT) AS topping_id
FROM pizza_runner.pizza_recipes;
```

**A ratings table with data validation**

```sql
CREATE TABLE runner_ratings (
    rating_id SERIAL PRIMARY KEY,
    order_id  INTEGER NOT NULL,
    runner_id INTEGER NOT NULL,
    rating    INTEGER CHECK (rating BETWEEN 1 AND 5)
);
```

---

## 📂 Files in This Folder

| File | Description |
|---|---|
| [📄 `Dataset.sql`](./Dataset.sql) | Creates the schema, tables and inserts the raw data |
| [🧹 `Data Cleaning and Transformation.sql`](./Data%20Cleaning%20and%20Transformation.sql) | Fixes NULLs, units and data types; builds two cleaned views |
| [🍕 `A. Pizza Metrics.sql`](./A.%20Pizza%20Metrics.sql) | 10 questions on order volume and pizza types |
| [🏃 `B. Runner and Customer Experience.sql`](./B.%20Runner%20and%20Customer%20Experience.sql) | 7 questions on runner speed, distance and reliability |
| [🧀 `C. Ingredient Optimisation.sql`](./C.%20Ingredient%20Optimisation.sql) | 6 questions on toppings, extras and exclusions |
| [💰 `D. Pricing and Ratings.sql`](./D.%20Pricing%20and%20Ratings.sql) | 5 questions on revenue, a new ratings table and profit |
| [🎁 `E.  Bonus Question.sql`](./E.%20%20Bonus%20Question.sql) | Extending the menu with a new Supreme pizza |

---

## 📬 Contact Me

<p align="center">
  <a href="https://www.linkedin.com/in/ayush-jena/"><img src="https://img.shields.io/badge/LinkedIn-Ayush%20Jena-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"/></a>
  <a href="mailto:ayushjena227@gmail.com"><img src="https://img.shields.io/badge/Email-ayushjena227%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/></a>
  <a href="https://github.com/ayushjena1"><img src="https://img.shields.io/badge/GitHub-ayushjena1-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/></a>
</p>

<p align="center">⭐ If you found this helpful, consider giving the repo a star! ⭐</p>
