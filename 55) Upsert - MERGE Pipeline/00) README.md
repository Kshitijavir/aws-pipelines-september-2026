# 55) Snowflake — Upsert (MERGE) Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |

## 🎯 Goal

Now we move to one of the **most important Snowflake ETL concepts: `MERGE`**.

This pipeline will teach you how to handle:

* New records → **INSERT**
* Existing records → **UPDATE**
* Matching based on a key
* Source table → Target table
* `MERGE INTO`

The practical scenario:

```text
SOURCE / NEW DATA
       ↓
     MERGE
       ↓
TARGET EMPLOYEE TABLE
       ↓
Existing → UPDATE
New      → INSERT
```

---

## 🏗️ Pipeline Architecture

We'll create:

```text
NEW EMPLOYEE DATA
       │
       ↓
EMPLOYEE_SOURCE
       │
       │ MERGE
       ↓
EMPLOYEE_TARGET
```

We'll deliberately create:

### 👥 Existing employees

```text
6001 Rahul
6002 Priya
6003 Amit
```

### 🆕 New incoming data

```text
6002 Priya → Salary changed       → UPDATE
6003 Amit  → Department changed   → UPDATE
6004 Sneha → New employee         → INSERT
6005 Vikas → New employee         → INSERT
```

So after the `MERGE`:

```text
6001 → unchanged
6002 → updated
6003 → updated
6004 → inserted
6005 → inserted
```

---

## 🗄️ Step 1 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_MERGE_PRACTICE;

USE DATABASE SNOWFLAKE_MERGE_PRACTICE;
```

---

## 📂 Step 2 — Create the Schema

```sql
CREATE SCHEMA MERGE_SCHEMA;

USE SCHEMA MERGE_SCHEMA;
```

---

## ⚙️ Step 3 — Create the Warehouse

```sql
CREATE WAREHOUSE MERGE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE MERGE_WH;
```

---

## 🎯 Step 4 — Create the Target Table

This is the table that already contains our existing data.

```sql
CREATE TABLE EMPLOYEE_TARGET (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    DEPARTMENT    VARCHAR(50),
    CITY          VARCHAR(100),
    SALARY        NUMBER,
    UPDATED_DATE  DATE
);
```

---

## ✍️ Step 5 — Insert Existing Data

```sql
INSERT INTO EMPLOYEE_TARGET VALUES
(6001, 'Rahul Sharma', 'rahul@example.com', 'IT', 'Mumbai', 85000, '2026-09-01'),
(6002, 'Priya Patil', 'priya@example.com', 'HR', 'Pune', 62000, '2026-09-01'),
(6003, 'Amit Verma', 'amit@example.com', 'Finance', 'Delhi', 95000, '2026-09-01');
```

Check:

```sql
SELECT * FROM EMPLOYEE_TARGET ORDER BY EMPLOYEE_ID;
```

We currently have:

```text
6001 Rahul  IT       85000
6002 Priya  HR       62000
6003 Amit   Finance  95000
```

---

## 📋 Step 6 — Create the Source Table

This represents the **new incoming data**.

```sql
CREATE TABLE EMPLOYEE_SOURCE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    DEPARTMENT    VARCHAR(50),
    CITY          VARCHAR(100),
    SALARY        NUMBER
);
```

---

## ✍️ Step 7 — Insert New Incoming Data

```sql
INSERT INTO EMPLOYEE_SOURCE VALUES
(6002, 'Priya Patil', 'priya@example.com', 'HR', 'Pune', 70000),
(6003, 'Amit Verma', 'amit@example.com', 'IT', 'Delhi', 105000),
(6004, 'Sneha Joshi', 'sneha@example.com', 'Finance', 'Bengaluru', 78000),
(6005, 'Vikas Kumar', 'vikas@example.com', 'Sales', 'Hyderabad', 65000);
```

Notice carefully:

### 🔸 `6002`

Already exists but salary changed:

```text
Old → 62000
New → 70000
```

### 🔸 `6003`

Already exists but department and salary changed:

```text
Old → Finance / 95000
New → IT / 105000
```

### 🔸 `6004` and `6005`

Don't exist in target.

Therefore:

```text
6002 → UPDATE
6003 → UPDATE
6004 → INSERT
6005 → INSERT
```

---

## 🔍 Step 8 — Check the Source

```sql
SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;
```

---

## 🔀 Step 9 — Perform MERGE

Now the important part.

```sql
MERGE INTO EMPLOYEE_TARGET AS TARGET
USING EMPLOYEE_SOURCE AS SOURCE
ON TARGET.EMPLOYEE_ID = SOURCE.EMPLOYEE_ID

WHEN MATCHED THEN
    UPDATE SET
        TARGET.EMPLOYEE_NAME = SOURCE.EMPLOYEE_NAME,
        TARGET.EMAIL = SOURCE.EMAIL,
        TARGET.DEPARTMENT = SOURCE.DEPARTMENT,
        TARGET.CITY = SOURCE.CITY,
        TARGET.SALARY = SOURCE.SALARY,
        TARGET.UPDATED_DATE = CURRENT_DATE()

WHEN NOT MATCHED THEN
    INSERT (
        EMPLOYEE_ID,
        EMPLOYEE_NAME,
        EMAIL,
        DEPARTMENT,
        CITY,
        SALARY,
        UPDATED_DATE
    )
    VALUES (
        SOURCE.EMPLOYEE_ID,
        SOURCE.EMPLOYEE_NAME,
        SOURCE.EMAIL,
        SOURCE.DEPARTMENT,
        SOURCE.CITY,
        SOURCE.SALARY,
        CURRENT_DATE()
    );
```

---

## ✅ Step 10 — Check the Target

```sql
SELECT * FROM EMPLOYEE_TARGET ORDER BY EMPLOYEE_ID;
```

You should now have:

```text
6001 Rahul  IT       85000
6002 Priya  HR       70000   ← UPDATED
6003 Amit   IT       105000  ← UPDATED
6004 Sneha  Finance  78000   ← INSERTED
6005 Vikas  Sales    65000   ← INSERTED
```

---

## 🧠 Understand `MERGE`

The core logic is:

```text
                 SOURCE
                   │
                   ↓
            EMPLOYEE_ID match?
              /          \
            YES           NO
             ↓             ↓
           UPDATE       INSERT
```

The condition is:

```sql
ON TARGET.EMPLOYEE_ID = SOURCE.EMPLOYEE_ID
```

That means:

> "Use EMPLOYEE_ID to determine whether this employee already exists."

---

## 🧩 Step 11 — The Two Most Important Clauses

### ✅ `WHEN MATCHED`

```sql
WHEN MATCHED THEN
    UPDATE SET ...
```

Means:

> Record already exists → update it.

---

### ➕ `WHEN NOT MATCHED`

```sql
WHEN NOT MATCHED THEN
    INSERT (...)
    VALUES (...);
```

Means:

> Record doesn't exist → insert it.

---

## 💡 Step 12 — Why MERGE Is Important

Imagine your company receives this every day:

```text
employee_daily_file.csv
```

It contains:

```text
Existing employees
+
New employees
+
Updated employees
```

You don't want to manually run:

```text
UPDATE
UPDATE
UPDATE
INSERT
INSERT
INSERT
```

Instead:

```text
Daily Data
    ↓
Source
    ↓
MERGE
    ↓
Target
```

One operation handles both:

```text
UPDATE + INSERT
```

That's why `MERGE` is extremely common in data engineering.

---

## 🔁 Step 13 — Test the MERGE Again

Let's prove that the process works.

Add another employee:

```sql
INSERT INTO EMPLOYEE_SOURCE VALUES
(6006, 'Neha Singh', 'neha@example.com', 'IT', 'Mumbai', 88000);
```

Run the same `MERGE` again.

Then:

```sql
SELECT * FROM EMPLOYEE_TARGET ORDER BY EMPLOYEE_ID;
```

You'll now have:

```text
6001
6002
6003
6004
6005
6006   ← NEW
```

---

## ⚠️ Important Real-World Concept

`MERGE` needs a reliable matching key.

Here we're using:

```text
EMPLOYEE_ID
```

because it uniquely identifies an employee.

In real pipelines this could be:

```text
customer_id
order_id
product_id
account_id
```

depending on the dataset.

---

## 🎯 What You Learned in Pipeline 55

You have now practiced:

* Source table
* Target table
* Matching key
* `MERGE INTO`
* `WHEN MATCHED`
* `UPDATE`
* `WHEN NOT MATCHED`
* `INSERT`
* Upsert logic

