-- ============================================================
-- 55) Snowflake — Upsert (MERGE) Pipeline
-- All the SQL from 00) README.md, in README order.
-- Paste the whole file into a Snowflake worksheet.
-- Run it from top to bottom.
-- MERGE means: old row, change it. New row, add it.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE   (README Step 1)
-- Makes a new database for this MERGE practice.
-- ============================================================

CREATE DATABASE SNOWFLAKE_MERGE_PRACTICE;

-- Use this database from now on.
USE DATABASE SNOWFLAKE_MERGE_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA   (README Step 2)
-- Makes a schema to hold our tables.
-- ============================================================

CREATE SCHEMA MERGE_SCHEMA;

-- Use this schema from now on.
USE SCHEMA MERGE_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE   (README Step 3)
-- Makes a small warehouse. It runs the SQL.
-- ============================================================

CREATE WAREHOUSE MERGE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Use this warehouse to run the SQL.
USE WAREHOUSE MERGE_WH;


-- ============================================================
-- 4. CREATE TARGET TABLE   (README Step 4)
-- The table that already has our old rows.
-- ============================================================

CREATE TABLE EMPLOYEE_TARGET (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    DEPARTMENT    VARCHAR(50),
    CITY          VARCHAR(100),
    SALARY        NUMBER,
    UPDATED_DATE  DATE
);

SELECT * FROM EMPLOYEE_TARGET;


-- ============================================================
-- 5. INSERT EXISTING DATA   (README Step 5)
-- Add the three employees we already have.
-- ============================================================

INSERT INTO EMPLOYEE_TARGET VALUES
(6001, 'Rahul Sharma', 'rahul@example.com', 'IT', 'Mumbai', 85000, '2026-09-01'),
(6002, 'Priya Patil', 'priya@example.com', 'HR', 'Pune', 62000, '2026-09-01'),
(6003, 'Amit Verma', 'amit@example.com', 'Finance', 'Delhi', 95000, '2026-09-01');

-- Show the rows in the target table now.
SELECT * FROM EMPLOYEE_TARGET ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 6. CREATE SOURCE TABLE   (README Step 6)
-- The table that holds the new rows coming in.
-- ============================================================

CREATE TABLE EMPLOYEE_SOURCE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    DEPARTMENT    VARCHAR(50),
    CITY          VARCHAR(100),
    SALARY        NUMBER
);

SELECT * FROM EMPLOYEE_SOURCE;


-- ============================================================
-- 7. INSERT NEW INCOMING DATA   (README Step 7)
-- 6002 and 6003 are already there. They get changed.
-- 6004 and 6005 are new. They get added.
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(6002, 'Priya Patil', 'priya@example.com', 'HR', 'Pune', 70000),
(6003, 'Amit Verma', 'amit@example.com', 'IT', 'Delhi', 105000),
(6004, 'Sneha Joshi', 'sneha@example.com', 'Finance', 'Bengaluru', 78000),
(6005, 'Vikas Kumar', 'vikas@example.com', 'Sales', 'Hyderabad', 65000);


-- ============================================================
-- 8. CHECK THE SOURCE   (README Step 8)
-- Show the new rows before the MERGE runs.
-- ============================================================

SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 9. RUN THE MERGE   (README Step 9)
-- This is the main step.
-- EMPLOYEE_ID is the key we match on.
-- Old row: change it. New row: add it.
-- ============================================================

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


-- ============================================================
-- 10. CHECK THE TARGET   (README Step 10)
-- 6002 and 6003 are changed. 6004 and 6005 are added.
-- ============================================================

SELECT * FROM EMPLOYEE_TARGET ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 11. TEST THE MERGE AGAIN   (README Step 13)
-- Add one more employee to the source table.
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(6006, 'Neha Singh', 'neha@example.com', 'IT', 'Mumbai', 88000);

-- Run the MERGE again to see the same result
