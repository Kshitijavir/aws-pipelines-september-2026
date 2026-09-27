# 54) Snowflake — SQL Transformation Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [snowflake.sql](snowflake.sql) | Every SQL statement for this pipeline in one file, ready to paste into a Snowflake worksheet |

## 🎯 Goal

This one matters a lot. Here we practise **transforming data inside Snowflake using SQL**.

```text
Raw Employee Data
       ↓
   RAW_EMPLOYEE
       ↓
SQL Transformations
       ↓
TRANSFORMED_EMPLOYEE
```

We will practise:

* `SELECT` — picks the columns you want
* `WHERE` — keeps only the rows you want
* `CASE` — picks a value based on a rule
* Calculated columns — new columns you work out in the query
* String functions — they change text
* Date functions — they work with dates
* Aggregations — totals, counts and averages
* `GROUP BY` — groups rows so you can total them
* Making a transformed table using `CREATE TABLE AS SELECT` (CTAS)

And we will keep it **pure Snowflake**. No AWS.

---

## 🗄️ Step 1 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_TRANSFORMATION_PRACTICE;

USE DATABASE SNOWFLAKE_TRANSFORMATION_PRACTICE;
```

---

## 📂 Step 2 — Create the Schema

```sql
CREATE SCHEMA TRANSFORMATION_SCHEMA;

USE SCHEMA TRANSFORMATION_SCHEMA;
```

---

## ⚙️ Step 3 — Create the Warehouse

```sql
CREATE WAREHOUSE TRANSFORMATION_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE TRANSFORMATION_WH;
```

---

## 📋 Step 4 — Create the Raw Employee Table

This is the **source table**. Another word for it is the **raw table**. It holds the data just as it came in.

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

## ✍️ Step 5 — Insert Sample Data

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

## 🔄 Step 6 — Basic Transformation

First let us make a table with the changed data.

We will:

* Make the employee name uppercase (capital letters)
* Make the email lowercase (small letters)
* Add 10% to the salary
* Put each salary into a category

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

## 🔍 Step 7 — Check the Transformed Table

```sql
SELECT * FROM TRANSFORMED_EMPLOYEE;
```

The table has these columns:

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

For example, here is the first row:

```text
5001 | RAHUL SHARMA | rahul.sharma@example.com | IT | Mumbai | 2023-01-15 | 85000 | 93500 | MEDIUM
```

---

## 🎯 Step 8 — Practice `WHERE`

Now let us make another table. This one holds only the IT employees.

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

## 📊 Step 9 — Practice Aggregation

Now let us work out numbers for each department.

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

The result looks like this:

```text
DEPARTMENT | EMPLOYEE_COUNT | TOTAL_SALARY | AVERAGE_SALARY | MIN_SALARY | MAX_SALARY
-----------+----------------+--------------+----------------+------------+-----------
Finance    | 2              | ...          | ...            | ...        | ...
HR         | 1              | ...          | ...            | ...        | ...
IT         | 3              | ...          | ...            | ...        | ...
Sales      | 2              | ...          | ...            | ...        | ...
```

---

## 💾 Step 10 — Create the Department Summary Table

Now let us save that result in a table.

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

## 📅 Step 11 — Practice Date Transformation

Let us work out how many years each employee has worked here.

```sql
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    JOINING_DATE,
    DATEDIFF(YEAR, JOINING_DATE, CURRENT_DATE()) AS YEARS_WITH_COMPANY
FROM RAW_EMPLOYEE;
```

---

## 🔤 Step 12 — Practice String Transformation

```sql
SELECT
    EMPLOYEE_NAME,
    UPPER(EMPLOYEE_NAME) AS UPPER_NAME,
    LOWER(EMPLOYEE_NAME) AS LOWER_NAME,
    LENGTH(EMPLOYEE_NAME) AS NAME_LENGTH
FROM RAW_EMPLOYEE;
```

---

## 🔀 Step 13 — Practice Conditional Transformation

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

The main idea of Pipeline 54 is this:

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

We use this:

```sql
CREATE TABLE ... AS
SELECT ...
```

This is called **CTAS**. CTAS is short for Create Table As Select.

It means:

> Run the query. Then make a new table that holds the result of the query.

