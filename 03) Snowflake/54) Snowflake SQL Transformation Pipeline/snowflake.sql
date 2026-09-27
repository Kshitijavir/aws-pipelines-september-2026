-- ============================================================
-- 54) Snowflake — SQL Transformation Pipeline
-- Every SQL statement from the README, in the same order.
-- Paste this whole file into a Snowflake worksheet and run it.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- Creates a separate database for the SQL transformation practice
-- ============================================================

CREATE DATABASE SNOWFLAKE_TRANSFORMATION_PRACTICE;


-- Selects the database for the remaining operations
USE DATABASE SNOWFLAKE_TRANSFORMATION_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Creates a schema to organize all project objects
-- ============================================================

CREATE SCHEMA TRANSFORMATION_SCHEMA;


-- Selects the schema for the remaining operations
USE SCHEMA TRANSFORMATION_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Creates an XSMALL compute warehouse for this practice project
-- ============================================================

CREATE WAREHOUSE TRANSFORMATION_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;


-- Selects the warehouse used to run the queries
USE WAREHOUSE TRANSFORMATION_WH;


-- ============================================================
-- 4. CREATE RAW EMPLOYEE TABLE
-- Creates the source table that holds the data as it came in
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


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- Inserts the sample employee rows into the raw table
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
-- Makes a new table with the data changed:
-- name in capitals, email in small letters, salary + 10%
-- and a salary category
-- ============================================================

-- The table TRANSFORMED_EMPLOYEE must not already exist, or this fails
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
-- 8. PRACTICE WHERE
-- Makes a new table that holds only the IT employees
-- ============================================================

-- The table IT_EMPLOYEES must not already exist, or this fails
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
-- 9. PRACTICE AGGREGATION
-- Works out the totals and averages for each department
-- ============================================================

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


-- ============================================================
-- 10. CREATE DEPARTMENT SUMMARY TABLE
-- Saves the department totals in a table
-- ============================================================

-- The table DEPARTMENT_SUMMARY must not already exist, or this fails
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


-- ============================================================
-- 11. PRACTICE DATE TRANSFORMATION
-- Works out how many years each employee has worked here
-- ============================================================

SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    JOINING_DATE,
    DATEDIFF(YEAR, JOINING_DATE, CURRENT_DATE()) AS YEARS_WITH_COMPANY
FROM RAW_EMPLOYEE;


-- ============================================================
-- 12. PRACTICE STRING TRANSFORMATION
-- Shows the name in capitals, in small letters, and its length
-- ============================================================

SELECT
    EMPLOYEE_NAME,
    UPPER(EMPLOYEE_NAME) AS UPPER_NAME,
    LOWER(EMPLOYEE_NAME) AS LOWER_NAME,
    LENGTH(EMPLOYEE_NAME) AS NAME_LENGTH
FROM RAW_EMPLOYEE;


-- ============================================================
-- 13. PRACTICE CONDITIONAL TRANSFORMATION
-- Gives each employee a salary grade from A to D
-- ============================================================

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
