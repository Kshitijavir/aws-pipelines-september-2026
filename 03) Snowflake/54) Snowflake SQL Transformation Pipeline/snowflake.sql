-- ============================================================
-- 54) Snowflake — SQL Transformation Pipeline
-- All the SQL from the README, in the same order.
-- Paste this whole file into a Snowflake worksheet and run it.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- Makes a new database for this practice
-- ============================================================

CREATE DATABASE SNOWFLAKE_TRANSFORMATION_PRACTICE;


-- Picks the database for the next steps
USE DATABASE SNOWFLAKE_TRANSFORMATION_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Makes a schema to keep the tables together
-- ============================================================

CREATE SCHEMA TRANSFORMATION_SCHEMA;


-- Picks the schema for the next steps
USE SCHEMA TRANSFORMATION_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Makes a small warehouse to run the queries
-- ============================================================

CREATE WAREHOUSE TRANSFORMATION_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;


-- Picks the warehouse that runs the queries
USE WAREHOUSE TRANSFORMATION_WH;


-- ============================================================
-- 4. CREATE RAW EMPLOYEE TABLE
-- Makes the source table. It holds the data as it came in
-- ============================================================

CREATE TABLE RAW_EMPLOYEE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    DEPARTMENT    VARCHAR(50),
    CITY          VARCHAR(100),
    JOINING_DATE  DATE,
    SALARY        NUMBER
);

SELECT * FROM RAW_EMPLOYEE;


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- Puts the sample rows into the raw table
-- ============================================================

INSERT INTO RAW_EMPLOYEE VALUES
(5001, 'Rahul Sharma', 'RAHUL.SHARMA@EXAMPLE.COM', 'IT', 'Mumbai', '2023-01-15', 85000),
(5002, 'Priya Patil', 'PRIYA.PATIL@EXAMPLE.COM', 'HR', 'Pune', '2022-06-20', 62000),
(5003, 'Amit Verma', 'AMIT.VERMA@EXAMPLE.COM', 'Finance', 'Delhi', '2021-03-10', 95000),
(5004, 'Sneha Joshi', 'SNEHA.JOSHI@EXAMPLE.COM', 'IT', 'Bengaluru', '2024-02-01', 72000),
(5005, 'Vikas Kumar', 'VIKAS.KUMAR@EXAMPLE.COM', 'Sales', 'Hyderabad', '2023-08-18', 58000),
(5006, 'Neha Singh', 'NEHA.SINGH@EXAMPLE.COM', 'IT', 'Mumbai', '2022-11-25', 105000),
(5007, 'Arjun Mehta', 'ARJUN.MEHTA@EXAMPLE.COM', 'Finance', 'Pune', '2020-09-12', 115000),
(5008, 'Pooja Desai', 'POOJA.DESAI@EXAMPLE.COM', 'Sales', 'Delhi', '2024-05-05', 54000);


-- Shows the rows that were inserted
SELECT * FROM RAW_EMPLOYEE;


-- ============================================================
-- 6. BASIC TRANSFORMATION
-- Makes a new table with changed data:
-- names in capital letters, emails in small letters,
-- salary plus 10%, and a salary group name
-- ============================================================

-- This fails if the table is already there
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


-- ============================================================
-- 7. CHECK THE TRANSFORMED TABLE
-- Shows the rows in the new table
-- ============================================================

SELECT * FROM TRANSFORMED_EMPLOYEE;


-- ============================================================
-- 8. CREATE IT EMPLOYEES TABLE
-- Makes a new table with only the IT employees
-- ============================================================

-- This fails if the table is already there
CREATE TABLE IT_EMPLOYEES AS
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    EMAIL,
    CITY,
    SALARY
FROM RAW_EMPLOYEE
WHERE DEPARTMENT = 'IT';


-- Shows the rows in the new table
SELECT * FROM IT_EMPLOYEES;


-- ============================================================
-- 10. CREATE DEPARTMENT SUMMARY TABLE
-- Saves the department totals in a table
-- ============================================================

-- This fails if the table is already there
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


-- Shows the rows in the summary table
SELECT * FROM DEPARTMENT_SUMMARY;
