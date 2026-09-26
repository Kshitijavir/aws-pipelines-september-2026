# 54) Snowflake — SQL Transformation Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |

This pipeline is **Snowflake only** — no AWS component. It follows on from [50) Snowflake — Basic CSV Batch Load Pipeline](../50%29%20Snowflake%20Basic%20CSV%20Batch%20Load%20Pipeline/00%29%20README.md), [51) Snowflake — Multi-File CSV Batch Load Pipeline](../51%29%20Snowflake%20Multi-File%20CSV%20Batch%20Load%20Pipeline/00%29%20README.md), [52) Snowflake — Table-to-Stage Export Pipeline](../52%29%20Snowflake%20Table-to-Stage%20Export%20Pipeline/00%29%20README.md) and [53) Incremental File Load Pipeline](../53%29%20Incremental%20File%20Load%20Pipeline/00%29%20README.md).

## 🎯 Goal

This one is important because now we practise **transforming data inside Snowflake using SQL**.

```text
Raw Employee Data
       ↓
   RAW_EMPLOYEE
       ↓
SQL Transformations
       ↓
TRANSFORMED_EMPLOYEE
```

We'll practice:

* `SELECT`
* `WHERE`
* `CASE`
* Calculated columns
* String functions
* Date functions
* Aggregations
* `GROUP BY`
* Creating a transformed table using `CREATE TABLE AS SELECT` (CTAS)

And we'll keep it **pure Snowflake** — no AWS.

---

## Step 1 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_TRANSFORMATION_PRACTICE;

USE DATABASE SNOWFLAKE_TRANSFORMATION_PRACTICE;
```

---

## Step 2 — Create the Schema

```sql
CREATE SCHEMA TRANSFORMATION_SCHEMA;

USE SCHEMA TRANSFORMATION_SCHEMA;
```

---

## Step 3 — Create the Warehouse

```sql
CREATE WAREHOUSE TRANSFORMATION_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE TRANSFORMATION_WH;
```

---

## Step 4 — Create the Raw Employee Table

This is the **source / raw table**.

```sql
CREATE TABLE RAW_EMPLOYEE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    DEPARTMENT    VARCHAR(50),
    CITY          VARCHAR(100),
    JOINING_DATE  DATE,
    SALARY        NUMBER
);
```

---

## Step 5 — Insert Sample Data

```sql
INSERT INTO RAW_EMPLOYEE VALUES
(5001, 'Rahul Sharma', 'RAHUL.SHARMA@EXAMPLE.COM', 'IT', 'Mumbai', '2023-01-15', 85000),
(5002, 'Priya Patil', 'PRIYA.PATIL@EXAMPLE.COM', 'HR', 'Pune', '2022-06-20', 62000),
(5003, 'Amit Verma', 'AMIT.VERMA@EXAMPLE.COM', 'Finance', 'Delhi', '2021-03-10', 95000),
(5004, 'Sneha Joshi', 'SNEHA.JOSHI@EXAMPLE.COM', 'IT', 'Bengaluru', '2024-02-01', 72000),
(5005, 'Vikas Kumar', 'VIKAS.KUMAR@EXAMPLE.COM', 'Sales', 'Hyderabad', '2023-08-18', 58000),
(5006, 'Neha Singh', 'NEHA.SINGH@EXAMPLE.COM', 'IT', 'Mumbai', '2022-11-25', 105000),
(5007, 'Arjun Mehta', 'ARJUN.MEHTA@EXAMPLE.COM', 'Finance', 'Pune', '2020-09-12', 115000),
(5008, 'Pooja Desai', 'POOJA.DESAI@EXAMPLE.COM', 'Sales', 'Delhi', '2024-05-05', 54000);
```

Check:

```sql
SELECT * FROM RAW_EMPLOYEE;
```

---

## Step 6 — Basic Transformation

First let's create a transformed table.

We will:

* Convert employee name to uppercase
* Convert email to lowercase
* Increase salary by 10%
* Create a salary category

```sql
CREATE TABLE TRANSFORMED_EMPLOYEE AS
SELECT
    EMPLOYEE_ID,
    UPPER(EMPLOYEE_NAME) AS EMPLOYEE_NAME,
    LOWER(EMAIL)         AS EMAIL,
    DEPARTMENT,
    CITY,
    JOINING_DATE,
    SALARY,
    SALARY * 1.10 AS SALARY_AFTER_10_PERCENT,
    CASE
        WHEN SALARY >= 100000 THEN 'HIGH'
        WHEN SALARY >= 70000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS SALARY_CATEGORY
FROM RAW_EMPLOYEE;
```

---

## Step 7 — Check the Transformed Table

```sql
SELECT * FROM TRANSFORMED_EMPLOYEE;
```

The result has these columns:

```text
EMPLOYEE_ID
EMPLOYEE_NAME
EMAIL
DEPARTMENT
CITY
JOINING_DATE
SALARY
SALARY_AFTER_10_PERCENT
SALARY_CATEGORY
```

For example, the first row:

```text
5001 | RAHUL SHARMA | rahul.sharma@example.com | IT | Mumbai | 2023-01-15 | 85000 | 93500 | MEDIUM
```

---

## Step 8 — Practice `WHERE`

Now let's create another transformed table containing only IT employees.

```sql
CREATE TABLE IT_EMPLOYEES AS
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    EMAIL,
    CITY,
    SALARY
FROM RAW_EMPLOYEE
WHERE DEPARTMENT = 'IT';
```

Check:

```sql
SELECT * FROM IT_EMPLOYEES;
```

---

## Step 9 — Practice Aggregation

Now let's calculate department-level statistics.

```sql
SELECT
    DEPARTMENT,
    COUNT(*)     AS EMPLOYEE_COUNT,
    SUM(SALARY)  AS TOTAL_SALARY,
    AVG(SALARY)  AS AVERAGE_SALARY,
    MIN(SALARY)  AS MIN_SALARY,
    MAX(SALARY)  AS MAX_SALARY
FROM RAW_EMPLOYEE
GROUP BY DEPARTMENT
ORDER BY DEPARTMENT;
```

This produces something like:

```text
DEPARTMENT | EMPLOYEE_COUNT | TOTAL_SALARY | AVERAGE_SALARY | MIN_SALARY | MAX_SALARY
-----------+----------------+--------------+----------------+------------+-----------
Finance    | 2              | ...          | ...            | ...        | ...
HR         | 1              | ...          | ...            | ...        | ...
IT         | 3              | ...          | ...            | ...        | ...
Sales      | 2              | ...          | ...            | ...        | ...
```

---

## Step 10 — Create the Department Summary Table

Now let's actually persist that transformation.

```sql
CREATE TABLE DEPARTMENT_SUMMARY AS
SELECT
    DEPARTMENT,
    COUNT(*)     AS EMPLOYEE_COUNT,
    SUM(SALARY)  AS TOTAL_SALARY,
    AVG(SALARY)  AS AVERAGE_SALARY,
    MIN(SALARY)  AS MIN_SALARY,
    MAX(SALARY)  AS MAX_SALARY
FROM RAW_EMPLOYEE
GROUP BY DEPARTMENT;
```

Check:

```sql
SELECT * FROM DEPARTMENT_SUMMARY;
```

---

## Step 11 — Practice Date Transformation

Let's calculate how many years an employee has been working.

```sql
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    JOINING_DATE,
    DATEDIFF(YEAR, JOINING_DATE, CURRENT_DATE()) AS YEARS_WITH_COMPANY
FROM RAW_EMPLOYEE;
```

---

## Step 12 — Practice String Transformation

```sql
SELECT
    EMPLOYEE_NAME,
    UPPER(EMPLOYEE_NAME) AS UPPER_NAME,
    LOWER(EMPLOYEE_NAME) AS LOWER_NAME,
    LENGTH(EMPLOYEE_NAME) AS NAME_LENGTH
FROM RAW_EMPLOYEE;
```

---

## Step 13 — Practice Conditional Transformation

```sql
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    SALARY,
    CASE
        WHEN SALARY >= 100000 THEN 'A'
        WHEN SALARY >= 70000  THEN 'B'
        WHEN SALARY >= 50000  THEN 'C'
        ELSE 'D'
    END AS SALARY_GRADE
FROM RAW_EMPLOYEE;
```

---

## 🧠 What You Should Understand

The main idea of Pipeline 54 is:

```text
              RAW TABLE
                  │
                  ↓
          SQL Transformation
                  │
       ┌──────────┼──────────┐
       ↓          ↓          ↓
     Filter   Calculate   Transform
       │          │          │
       └──────────┼──────────┘
                  ↓
            TARGET TABLE
```

For example:

```text
RAW_EMPLOYEE
     │
     ├── UPPER()
     ├── LOWER()
     ├── CASE
     ├── SALARY calculation
     ├── WHERE
     ├── GROUP BY
     └── DATE functions
              ↓
    TRANSFORMED_EMPLOYEE
```

### 🔥 The important Snowflake concept here

We're using:

```sql
CREATE TABLE ... AS
SELECT ...
```

This is called **CTAS — Create Table As Select**.

It means:

> Execute the query and create a new table containing the query result.

