# 59) Snowflake — SCD Type 2 Historical Tracking Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |

---

## 🧠 First: What Is SCD Type 2?

SCD = Slowly Changing Dimension.

SCD Type 2 means:

When a customer's important information changes, don't overwrite the old record. Keep the old version and create a new version.

### 📋 Example

Initially:

```text
CUSTOMER_ID | NAME  | CITY   | SALARY | START_DATE | END_DATE   | CURRENT
1001        | Rahul | Mumbai | 75000  | 2026-09-01 | 9999-12-31 | TRUE
```

Later Rahul moves to Pune and salary changes:

```text
CUSTOMER_ID | NAME  | CITY   | SALARY | START_DATE | END_DATE   | CURRENT
1001        | Rahul | Mumbai | 75000  | 2026-09-01 | 2026-09-26 | FALSE
1001        | Rahul | Pune   | 85000  | 2026-09-27 | 9999-12-31 | TRUE
```

🔥 The old record is NOT deleted.

That's the whole point of SCD Type 2.

### ⚖️ SCD Type 1 vs Type 2

**Type 1** — old value is overwritten:

Before:

```text
1001 | Rahul | Mumbai
```

After:

```text
1001 | Rahul | Pune
```

History is lost.

**Type 2** — old value is preserved:

```text
1001 | Rahul | Mumbai | FALSE
1001 | Rahul | Pune   | TRUE
```

History is maintained.

---

## 🎯 Goal

Suppose we have:

```text
Customer 1001
Rahul
Mumbai
₹75,000
```

Later Rahul moves to Bengaluru and salary becomes ₹85,000.

In **SCD Type 2**, we DON'T overwrite Mumbai.

We keep both:

```text
1001 | Rahul | Mumbai    | 75000 | Old     | FALSE
1001 | Rahul | Bengaluru | 85000 | Current | TRUE
```

---

## 🗄️ Step 1 — Create the Database, Schema and Warehouse

```sql
CREATE DATABASE SNOWFLAKE_SCD2_PRACTICE;

USE DATABASE SNOWFLAKE_SCD2_PRACTICE;

CREATE SCHEMA SCD2_SCHEMA;

USE SCHEMA SCD2_SCHEMA;
```

Create the warehouse:

```sql
CREATE WAREHOUSE SCD2_WH
    WAREHOUSE_SIZE = XSMALL;

USE WAREHOUSE SCD2_WH;
```

---

## 📋 Step 2 — Create the Source Table

This is our incoming/current customer data.

```sql
CREATE TABLE CUSTOMER_SOURCE (
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY          VARCHAR(100),
    SALARY        NUMBER
);
```

Insert initial data:

```sql
INSERT INTO CUSTOMER_SOURCE VALUES
(1001, 'Rahul Sharma', 'Mumbai', 75000),
(1002, 'Priya Patil', 'Pune', 62000),
(1003, 'Amit Verma', 'Delhi', 58000);
```

Check:

```sql
SELECT * FROM CUSTOMER_SOURCE;
```

---

## 📋 Step 3 — Create the SCD Type 2 Target Table

This table stores **history**.

```sql
CREATE TABLE CUSTOMER_HISTORY (
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY          VARCHAR(100),
    SALARY        NUMBER,
    VALID_FROM    TIMESTAMP,
    VALID_TO      TIMESTAMP,
    IS_CURRENT    BOOLEAN
);
```

---

## 🚚 Step 4 — Initial Load

Load the first version of every customer:

```sql
INSERT INTO CUSTOMER_HISTORY
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    SALARY,
    CURRENT_TIMESTAMP(),
    '9999-12-31 23:59:59',
    TRUE
FROM CUSTOMER_SOURCE;
```

Check:

```sql
SELECT * FROM CUSTOMER_HISTORY ORDER BY CUSTOMER_ID;
```

You'll have:

```text
1001 | Rahul Sharma | Mumbai | 75000 | ... | 9999-12-31 | TRUE
1002 | Priya Patil  | Pune   | 62000 | ... | 9999-12-31 | TRUE
1003 | Amit Verma   | Delhi  | 58000 | ... | 9999-12-31 | TRUE
```

---

## 🔄 Step 5 — Simulate a Customer Change

Now Rahul moves from Mumbai to Bengaluru.

Update the source:

```sql
UPDATE CUSTOMER_SOURCE
SET CITY = 'Bengaluru',
    SALARY = 85000
WHERE CUSTOMER_ID = 1001;
```

Check:

```sql
SELECT * FROM CUSTOMER_SOURCE WHERE CUSTOMER_ID = 1001;
```

Now source says:

```text
1001 | Rahul Sharma | Bengaluru | 85000
```

---

## ⏹️ Step 6 — Expire the Old Record

Now we close Rahul's old Mumbai record.

```sql
UPDATE CUSTOMER_HISTORY
SET VALID_TO = CURRENT_TIMESTAMP(),
    IS_CURRENT = FALSE
WHERE CUSTOMER_ID = 1001
  AND IS_CURRENT = TRUE;
```

Check:

```sql
SELECT * FROM CUSTOMER_HISTORY WHERE CUSTOMER_ID = 1001;
```

Old record is now:

```text
Rahul | Mumbai | 75000 | FALSE
```

---

## ➕ Step 7 — Insert the New Version

Now insert Rahul's new information:

```sql
INSERT INTO CUSTOMER_HISTORY
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    SALARY,
    CURRENT_TIMESTAMP(),
    '9999-12-31 23:59:59',
    TRUE
FROM CUSTOMER_SOURCE
WHERE CUSTOMER_ID = 1001;
```

---

## ✅ Step 8 — Check the History

```sql
SELECT * FROM CUSTOMER_HISTORY WHERE CUSTOMER_ID = 1001 ORDER BY VALID_FROM;
```

You should now have:

```text
CUSTOMER_ID | NAME         | CITY       | SALARY | IS_CURRENT
----------------------------------------------------------------
1001        | Rahul Sharma | Mumbai     | 75000  | FALSE
1001        | Rahul Sharma | Bengaluru  | 85000  | TRUE
```

### ✅ That's SCD Type 2

---

## 🔥 The Main Logic

Remember only these **3 steps**:

```text
Customer changes
       ↓
Close old record
IS_CURRENT = FALSE
       ↓
Insert new record
IS_CURRENT = TRUE
```

Visual:

```text
SOURCE
  │
  │ Rahul changes
  ↓
CUSTOMER_HISTORY
  │
  ├── Mumbai     ₹75,000  → FALSE
  │
  └── Bengaluru  ₹85,000  → TRUE
```

### ⚖️ SCD Type 1 vs Type 2 — Summary

| Type | What happens |
| ---- | ------------ |
| SCD Type 1 | Old value is overwritten |
| SCD Type 2 | Old value is preserved + new version inserted |

**For your practical roadmap, this simple version is enough to understand SCD Type 2.**
