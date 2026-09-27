-- ============================================================
-- 55) Snowflake — Upsert (MERGE) Pipeline
-- Every SQL statement from 00) README.md, in README order.
-- Paste this whole file into a Snowflake worksheet and run it
-- top to bottom.
-- MERGE means: if the row is already there, update it.
--              if the row is new, add it.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE   (README Step 1)
-- Creates a separate database for this MERGE practice project
-- ============================================================

CREATE DATABASE SNOWFLAKE_MERGE_PRACTICE;

-- Selects the database for the remaining operations
USE DATABASE SNOWFLAKE_MERGE_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA   (README Step 2)
-- Creates a schema to organize all project objects
-- ============================================================

CREATE SCHEMA MERGE_SCHEMA;

-- Selects the schema for the remaining operations
USE SCHEMA MERGE_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE   (README Step 3)
-- Creates an XSMALL compute warehouse for this practice project
-- ============================================================

CREATE WAREHOUSE MERGE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Selects the warehouse used to execute queries
USE WAREHOUSE MERGE_WH;


-- ============================================================
-- 4. CREATE TARGET TABLE   (README Step 4)
-- The table that already holds the data we have
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


-- ============================================================
-- 5. INSERT EXISTING DATA   (README Step 5)
-- Adds the three employees we already have
-- ============================================================

INSERT INTO EMPLOYEE_TARGET VALUES
(6001, 'Rahul Sharma', 'rahul@example.com', 'IT', 'Mumbai', 85000, '2026-09-01'),
(6002, 'Priya Patil', 'priya@example.com', 'HR', 'Pune', 62000, '2026-09-01'),
(6003, 'Amit Verma', 'amit@example.com', 'Finance', 'Delhi', 95000, '2026-09-01');

-- Shows what the target table holds right now
SELECT * FROM EMPLOYEE_TARGET ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 6. CREATE SOURCE TABLE   (README Step 6)
-- The table that holds the new data coming in
-- ============================================================

CREATE TABLE EMPLOYEE_SOURCE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    DEPARTMENT    VARCHAR(50),
    CITY          VARCHAR(100),
    SALARY        NUMBER
);


-- ============================================================
-- 7. INSERT NEW INCOMING DATA   (README Step 7)
-- 6002 and 6003 already exist, so they will be updated.
-- 6004 and 6005 are new, so they will be added.
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(6002, 'Priya Patil', 'priya@example.com', 'HR', 'Pune', 70000),
(6003, 'Amit Verma', 'amit@example.com', 'IT', 'Delhi', 105000),
(6004, 'Sneha Joshi', 'sneha@example.com', 'Finance', 'Bengaluru', 78000),
(6005, 'Vikas Kumar', 'vikas@example.com', 'Sales', 'Hyderabad', 65000);


-- ============================================================
-- 8. CHECK THE SOURCE   (README Step 8)
-- Shows the new incoming data before the MERGE runs
-- ============================================================

SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 9. RUN THE MERGE   (README Step 9)
-- This is the main step.
-- EMPLOYEE_ID is the matching key.
-- If the row is already there, update it. If it is new, add it.
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
-- 6002 and 6003 should now be updated, and 6004 and 6005 added
-- ============================================================

SELECT * FROM EMPLOYEE_TARGET ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 11. TEST THE MERGE AGAIN   (README Step 13)
-- Adds one more employee to the source, runs the MERGE again,
-- and checks the target. The MERGE is the same statement as in
-- section 9 above, so run it once more from there.
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(6006, 'Neha Singh', 'neha@example.com', 'IT', 'Mumbai', 88000);

-- Now run the same MERGE statement from section 9 again.

SELECT * FROM EMPLOYEE_TARGET ORDER BY EMPLOYEE_ID;
