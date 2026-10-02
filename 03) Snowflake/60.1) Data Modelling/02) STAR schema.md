# ⭐ Star Schema

## 1️⃣ Quick Recap — What We Already Know

In the previous note (`01) Data Modelling Basics.md`) we learned two types of tables:

- 🟩 **Dimension Table** → details / description (Who? What? Where?)
- 🟦 **Fact Table** → numbers / measurements (How much? How many?)

A new question now:

> 🤔 "If I keep **one Fact table in the middle** and put **many Dimension tables around it**, what is that design called?"

Answer → **Star Schema** ⭐

---

## 2️⃣ What is a Schema?

A **Schema** simply means **the design / plan / layout** of tables in a database 🗺️.

It tells us:

- 🏗️ Which tables exist
- 🔗 How tables are connected
- 🔑 Which columns are keys
- 📊 Which table is the main table

Think of it like a **building plan** 🏠. Before building a house we draw a plan. In the same way, before building a data warehouse we make a **schema**.

---

## 3️⃣ What is a Star Schema? Why the Name "Star"? 🌟

A **Star Schema** is a data warehouse design where:

- 🟦 **One Fact table sits in the center**
- 🟩 **Many Dimension tables sit around it**
- 🔗 Each Dimension connects **directly** to the Fact table

The name comes from the drawing 📝. It looks like a **star** ⭐ — Fact in the middle, Dimensions as the points.

```
                     ⭐ STAR SCHEMA ⭐

          DIM_DATE          DIM_PRODUCT
              │                  │
              ▼                  ▼
     DIM_CUSTOMER ──────► 🟦 FACT_SALES ◄────── DIM_STORE
              ▲                  ▲
              │                  │
          DIM_EMPLOYEE       DIM_PROMOTION
```

The Fact table is like the **sun** ☀️ and the Dimension tables are like the **planets** going around it 🪐.

---

## 4️⃣ The Three Parts of a Star Schema

| Part | What It Does | Example |
|---|---|---|
| 🟦 **Fact Table** | Stores numbers + keys | FACT_SALES |
| 🟩 **Dimension Table** | Stores details | DIM_PRODUCT |
| 🔗 **Keys** | Connects both tables | product_id |

### 🔑 Key rule

```
DIMENSION (Primary Key 🔑)
          │
          │ same column
          ▼
FACT (Foreign Key 🔗)
```

The Dimension table **owns** the key. The Fact table **borrows** the key.

---

## 5️⃣ Full Example — Retail Sales Shop 🛒

### 📋 Before modelling (one normal table)

| order_id | date | customer | city | product | category | store | qty | price | total |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-01-05 | Rahul | Bangalore | iPhone | Mobile | Store A | 2 | 50000 | 100000 |
| 2 | 2026-01-06 | Priya | Mumbai | Laptop | Electronics | Store B | 1 | 60000 | 60000 |
| 3 | 2026-01-07 | Amit | Delhi | iPhone | Mobile | Store A | 1 | 50000 | 50000 |

Problems with this table 😟:

- Same city name written again and again
- Same product name repeated
- Hard to query, slow to read

### ✂️ After modelling — split into 1 Fact + 4 Dimensions

**🟩 DIM_CUSTOMER** — `customer_id → Primary Key 🔑`

| customer_id | customer_name | city |
|---|---|---|
| CU01 | Rahul | Bangalore |
| CU02 | Priya | Mumbai |
| CU03 | Amit | Delhi |

**🟩 DIM_PRODUCT** — `product_id → Primary Key 🔑`

| product_id | product_name | category |
|---|---|---|
| P01 | iPhone | Mobile |
| P02 | Laptop | Electronics |

**🟩 DIM_STORE** — `store_id → Primary Key 🔑`

| store_id | store_name |
|---|---|
| S01 | Store A |
| S02 | Store B |

**🟩 DIM_DATE** — `date_id → Primary Key 🔑`

| date_id | full_date | day | month | year |
|---|---|---|---|---|
| D20260105 | 2026-01-05 | 05 | 01 | 2026 |
| D20260106 | 2026-01-06 | 06 | 01 | 2026 |

**🟦 FACT_SALES** (the center ⭐)

| order_id | customer_id | product_id | store_id | date_id | qty | price | total |
|---|---|---|---|---|---|---|---|
| 1 | CU01 | P01 | S01 | D20260105 | 2 | 50000 | 100000 |
| 2 | CU02 | P02 | S02 | D20260106 | 1 | 60000 | 60000 |
| 3 | CU03 | P01 | S01 | D20260107 | 1 | 50000 | 50000 |

Notice 👀:

- Names are **gone** — only IDs
- Numbers are **kept** — qty, price, total
- Every ID is a **Foreign Key 🔗**

```
DIM_CUSTOMER   DIM_PRODUCT   DIM_STORE   DIM_DATE
      ╲             │            │            ╱
       ╲            ▼            ▼           ╱
        ╲────► 🟦 FACT_SALES ◄────────────╱
```

---

## 6️⃣ Building It Step by Step 🪜

### 🪜 Step 1 — Take the normal table

```
order_id, date, customer, city, product, category, store, qty, price, total
```

### 🪜 Step 2 — Separate numbers from details

| Type | Columns |
|---|---|
| 📝 Details | date, customer, city, product, category, store |
| 📊 Numbers | qty, price, total |

### 🪜 Step 3 — Make one Dimension per topic

```
customer + city    → DIM_CUSTOMER
product + category → DIM_PRODUCT
store              → DIM_STORE
date               → DIM_DATE
```

### 🪜 Step 4 — Give each Dimension a key 🔑

```
customer_id, product_id, store_id, date_id
```

### 🪜 Step 5 — Put numbers + keys in the Fact table 🟦

```
FACT_SALES
├── customer_id 🔗      ├── qty    📊
├── product_id  🔗      ├── price  📊
├── store_id    🔗      └── total  📊
└── date_id     🔗
```

### 🪜 Step 6 — Connect everything with Foreign Keys

Done ✅ Your Star Schema is ready.

---

## 7️⃣ The Same Thing in SQL 💻

```sql
-- 🟩 Dimensions
CREATE TABLE dim_customer (
    customer_id   VARCHAR PRIMARY KEY,
    customer_name VARCHAR,
    city          VARCHAR
);

CREATE TABLE dim_product (
    product_id   VARCHAR PRIMARY KEY,
    product_name VARCHAR,
    category     VARCHAR
);

CREATE TABLE dim_date (
    date_id   VARCHAR PRIMARY KEY,
    full_date DATE,
    month     NUMBER,
    year      NUMBER
);

-- 🟦 Fact
CREATE TABLE fact_sales (
    order_id    NUMBER,
    customer_id VARCHAR REFERENCES dim_customer(customer_id),
    product_id  VARCHAR REFERENCES dim_product(product_id),
    date_id     VARCHAR REFERENCES dim_date(date_id),
    qty         NUMBER,
    price       NUMBER,
    total       NUMBER
);
```

The word `REFERENCES` is what creates the **star connections** ⭐.

---

## 8️⃣ How a Query Looks 🔍

Question ❓ → *"How much did we sell in Bangalore in January 2026?"*

```sql
SELECT c.city,
       SUM(f.total) AS total_sales
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
JOIN dim_date     d ON f.date_id     = d.date_id
WHERE c.city = 'Bangalore'
  AND d.month = 1
  AND d.year  = 2026
GROUP BY c.city;
```

See how easy it is? 👀

- The **Fact table** gives the numbers 📊
- The **Dimension tables** give the filters 🔍
- Only **1 join per dimension** — very clean

---

## 9️⃣ Why Star Schema is Fast ⚡

| Reason | Simple Meaning |
|---|---|
| 🔗 Few joins | Less work for the database |
| 🟩 Small dimensions | Easy to filter |
| 🟦 Big fact only once | Numbers stored in one place |
| 🧠 Simple to understand | Anyone can read the design |
| 🛠️ Easy for BI tools | Power BI / Tableau love star schema |

⭐ This is exactly why Power BI, Tableau and Snowflake users prefer Star Schema.

---

## 🔟 Where Star Schema is Weak ⚠️

| Problem | Explanation |
|---|---|
| 🔁 Repeated data in dimensions | Category repeats in many product rows |
| 🧩 Not fully normalised | Data is intentionally kept a bit duplicate |
| 🔄 Hard updates | Changing a name may need many row updates |
| 📦 Big dimension tables | Many attributes make dimensions grow |

But for **reporting and analytics** 📊 these problems are small. Speed matters more than saving a little space.

---

## 1️⃣1️⃣ Star Schema vs Snowflake Schema ❄️

### ⭐ Star Schema — dimensions are **flat**, one level only

```
     DIM_PRODUCT
     ┌─────────────┐
     │ product_id  │
     │ product     │
     │ category    │
     └──────┬──────┘
            ▼
       🟦 FACT_SALES
```

### ❄️ Snowflake Schema — dimensions are **split further**

```
     DIM_PRODUCT          DIM_CATEGORY
     ┌─────────────┐      ┌─────────────┐
     │ product_id  │      │ category_id │
     │ product     │─────►│ category    │
     │ category_id │      └─────────────┘
     └──────┬──────┘
            ▼
       🟦 FACT_SALES
```

| Point | ⭐ Star | ❄️ Snowflake |
|---|---|---|
| Joins needed | Few | Many |
| Speed | 🚀 Fast | 🐢 Slower |
| Storage | More | Less |
| Simplicity | 😀 Easy | 😕 Complex |
| Best for | Reporting / BI | Strict storage rules |

> 💡 **Remember:** Star = flat. Snowflake = broken into more pieces.

---

## 1️⃣2️⃣ What is "Grain" of a Fact Table? 🌾

**Grain** means → *"One row of the Fact table represents what?"*

| Fact Table | Grain |
|---|---|
| FACT_SALES | one row = **one product sold in one order** |
| FACT_ATTENDANCE | one row = **one student for one day** |
| FACT_PAYMENT | one row = **one payment made** |

```
Fine grain  🌾 = one row = small detail (more rows)
Coarse grain 🪵 = one row = big summary (fewer rows)
```

⚠️ Always decide the grain **first**. If the grain is wrong, the whole star schema is wrong.

---

## 1️⃣3️⃣ Simple Types of Facts and Dimensions 📚

| Type | Meaning | Example |
|---|---|---|
| 📌 **Transaction Fact** | One row per event | One sale |
| 📅 **Snapshot Fact** | One row per period | Monthly stock |
| ♻️ **Accumulating Fact** | Row updates as steps finish | Order placed → shipped → delivered |
| 🔗 **Conformed Dim** | Same dimension used by many facts | DIM_DATE used by Sales + Stock |
| 🧱 **Degenerate Dim** | Key with no extra table | order_id inside FACT_SALES |
| 🎭 **Role Playing Dim** | One dimension used for many purposes | DIM_DATE as order_date and ship_date |

Beginner tip: **90% of the time you will use Transaction Fact** 📌.

---

## 1️⃣4️⃣ Real Life Examples 🌍

| Area | Fact Table | Dimensions | Fact Numbers |
|---|---|---|---|
| 🏥 Hospital | FACT_TREATMENT | PATIENT, DOCTOR, DISEASE, DATE | treatment_cost, days_stayed |
| 🎓 School | FACT_RESULT | STUDENT, COURSE, EXAM | marks, attendance_percent |
| 🏦 Bank | FACT_TRANSACTION | ACCOUNT, BRANCH, DATE | amount, balance, charges |
| 🛒 E-Commerce | FACT_ORDER_ITEM | CUSTOMER, PRODUCT, SELLER, DATE | qty, price, discount |

Same shape every time ⭐ — Fact in the middle, Dimensions around it.

---

## 1️⃣5️⃣ Star Schema in Snowflake ❄️

In Snowflake, the star schema lives as a **fact table + dimension tables inside one schema**, and BI tools read it directly.

```
Database : SALES_DB
Schema   : ANALYTICS

   🟦 FACT_SALES
   🟩 DIM_CUSTOMER
   🟩 DIM_PRODUCT
   🟩 DIM_STORE
   🟩 DIM_DATE
```

### ⚠️ Loading order matters

```
1️⃣ Load DIMENSIONS first  → dim_customer, dim_product, dim_store, dim_date
2️⃣ Load FACT last         → fact_sales

Why? The Fact table needs the keys to already exist 🔑
```

### ✅ Handy Snowflake extras

- ❄️ **Clustering key** on `date_id` makes big fact tables faster
- 🚀 **Materialized views** can pre-join dimensions
- 📦 **COPY INTO / Snowpipe** loads facts and dims separately

---

## 1️⃣6️⃣ Common Beginner Mistakes 🚫

| Mistake | Why It Is Wrong | Fix |
|---|---|---|
| ❌ Keeping names inside Fact table | Wastes space, slow | Put names in Dimensions |
| ❌ No primary key in Dimensions | Cannot join properly | Always create a PK 🔑 |
| ❌ Not deciding grain first | Wrong totals | Decide grain first 🌾 |
| ❌ One huge "everything" dimension | Becomes messy | Split by topic |
| ❌ Forgetting DIM_DATE | No time reporting | Always add a date dimension 📅 |

---

## 1️⃣7️⃣ Star Schema or Snowflake — Which One? 🤷

```
Need speed + simple reports?          → ⭐ Star Schema
Need to save storage + strict rules?  → ❄️ Snowflake Schema
Not sure?                             → ⭐ Star Schema
```

> 💡 Modern cloud warehouses (Snowflake, BigQuery, Redshift) are so fast that people mostly choose **Star Schema** ⭐ and keep it simple.

---

## 1️⃣8️⃣ Quick Revision ⚡

```
⭐ STAR SCHEMA = 1 Fact in the center + many Dimensions around it
🟦 FACT       → Numbers 📊 + Foreign Keys 🔗
🟩 DIMENSION  → Names, categories, dates 📝 + Primary Key 🔑
```

```
Design rules:
✔ One fact table in the middle
✔ Dimensions connect directly to the fact
✔ No chains between dimensions
✔ Decide the grain first 🌾
✔ Load dimensions first, fact last
```

---

## 1️⃣9️⃣ Interview Questions 🎤

**Q1. What is a Star Schema?**
One fact table in the center with dimension tables connected around it.

**Q2. Why is it called Star Schema?**
Because the drawing looks like a star ⭐.

**Q3. Difference between Star and Snowflake Schema?**
Star = flat dimensions, fewer joins, faster. Snowflake = split dimensions, more joins, less storage.

**Q4. What is the grain of a fact table?**
What one row of the fact table represents.

**Q5. Which schema is best for Power BI?**
Star Schema ⭐ — BI tools are built for it.

**Q6. Can a Star Schema have more than one fact table?**
Yes. Then it becomes a **Galaxy Schema** (fact constellation) 🌌 — many facts sharing dimensions.

---

## 2️⃣0️⃣ One Line Summary 🎯

> ⭐ **Star Schema = a simple, fast design where one Fact table in the middle holds the numbers, and Dimension tables around it hold the details.**

```
        DIMENSIONS  🔍
      Who / What / Where
              │
              ▼
         🟦 FACT  📊
       How much / How many
```

Next topic to learn → **Snowflake Schema ❄️** and **Galaxy Schema 🌌**.
