# 60) End-to-End Snowflake Data Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [input files/](input%20files/) | `customer.csv` — the 5 rows loaded into the RAW table |

Now we connect the main Snowflake concepts you've learned into **one simple pipeline**.

## 🎯 Goal

```text
CSV File
   ↓
Stage
   ↓
COPY INTO
   ↓
RAW TABLE
   ↓
TRANSFORMATION
   ↓
FINAL TABLE
```

We will **not add Stream, Task, Stored Procedure, or SCD2** here. Those were already practiced separately.

---

## 🗄️ Step 1 — Create the Database, Schema and Warehouse

```sql
CREATE DATABASE SNOWFLAKE_END_TO_END_PRACTICE;

USE DATABASE SNOWFLAKE_END_TO_END_PRACTICE;

CREATE SCHEMA E2E_SCHEMA;

USE SCHEMA E2E_SCHEMA;
```

Create the warehouse:

```sql
CREATE WAREHOUSE E2E_WH
    WAREHOUSE_SIZE = XSMALL;

USE WAREHOUSE E2E_WH;
```

---

## 📋 Step 2 — Create the RAW Table

This table receives the CSV data exactly as it comes.

```sql
CREATE TABLE CUSTOMER_RAW (
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY          VARCHAR(100),
    SALARY        NUMBER
);
```

---

## 📄 Step 3 — Create the File Format

```sql
CREATE FILE FORMAT CUSTOMER_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';
```

---

## 📥 Step 4 — Create the Stage

```sql
CREATE STAGE CUSTOMER_STAGE
    FILE_FORMAT = CUSTOMER_CSV_FORMAT;
```

---

## 📋 Step 5 — Create the FINAL Table

This is where we want our cleaned data.

```sql
CREATE TABLE CUSTOMER_FINAL (
    CUSTOMER_ID     NUMBER,
    CUSTOMER_NAME   VARCHAR(100),
    CITY            VARCHAR(100),
    SALARY          NUMBER,
    SALARY_CATEGORY VARCHAR(20)
);
```

## 📝 Step 6 — Get the Input CSV

Source file: [input files/customer.csv](input%20files/customer.csv)

This file is uploaded to the `CUSTOMER_STAGE` stage.

---

## ⬆️ Step 7 — Upload the CSV to the Stage

In Snowsight:

```text
Data → Databases → SNOWFLAKE_END_TO_END_PRACTICE → E2E_SCHEMA → Stages → CUSTOMER_STAGE → Upload
```

Upload `customer.csv`, then check:

```sql
LIST @CUSTOMER_STAGE;
```

You should see:

```text
customer.csv
```

---

## 🚚 Step 8 — Load the CSV into the RAW Table

```sql
COPY INTO CUSTOMER_RAW
FROM @CUSTOMER_STAGE;
```

Check:

```sql
SELECT * FROM CUSTOMER_RAW;
```

You should see:

```text
1001 | Rahul Sharma | Mumbai     | 75000
1002 | Priya Patil  | Pune       | 62000
1003 | Amit Verma   | Delhi      | 58000
1004 | Sneha Joshi  | Bengaluru  | 95000
1005 | Vikas Kumar  | Hyderabad  | 45000
```

---

## 🔄 Step 9 — Transform the Data

Now we transform the RAW data before putting it into the final table.

Our rule:

```text
Salary >= 90000  → HIGH
Salary >= 60000  → MEDIUM
Salary <  60000  → LOW
```

Run:

```sql
INSERT INTO CUSTOMER_FINAL
SELECT
    CUSTOMER_ID,
    UPPER(CUSTOMER_NAME),
    UPPER(CITY),
    SALARY,
    CASE
        WHEN SALARY >= 90000 THEN 'HIGH'
        WHEN SALARY >= 60000 THEN 'MEDIUM'
        ELSE 'LOW'
    END
FROM CUSTOMER_RAW;
```

---

## ✅ Step 10 — Check the FINAL Table

```sql
SELECT * FROM CUSTOMER_FINAL ORDER BY CUSTOMER_ID;
```

Expected:

```text
CUSTOMER_ID | CUSTOMER_NAME | CITY       | SALARY | SALARY_CATEGORY
--------------------------------------------------------------------
1001        | RAHUL SHARMA  | MUMBAI     | 75000  | MEDIUM
1002        | PRIYA PATIL   | PUNE       | 62000  | MEDIUM
1003        | AMIT VERMA    | DELHI      | 58000  | LOW
1004        | SNEHA JOSHI   | BENGALURU  | 95000  | HIGH
1005        | VIKAS KUMAR   | HYDERABAD  | 45000  | LOW
```

---

## 🧠 Understand the Complete Pipeline

```text
             customer.csv
                  │
                  ▼
          ┌───────────────┐
          │     STAGE     │
          └───────┬───────┘
                  │
              COPY INTO
                  │
                  ▼
          ┌───────────────┐
          │   RAW TABLE   │
          └───────┬───────┘
                  │
            TRANSFORMATION
                  │
                  ▼
          ┌───────────────┐
          │ FINAL TABLE   │
          └───────────────┘
```

### ⭐ What You Learned

| Component | Purpose |
| --------- | ------- |
| CSV | Source data |
| Stage | Holds the file |
| File Format | Tells Snowflake how to read CSV |
| COPY INTO | Loads file into table |
| RAW Table | Original loaded data |
| SQL Transformation | Cleans/transforms data |
| FINAL Table | Business-ready data |

This is the **simple end-to-end Snowflake pipeline**. ✅

After this, your next practical can be a more realistic **incremental end-to-end pipeline** where new files arrive and only new/changed records are processed.
