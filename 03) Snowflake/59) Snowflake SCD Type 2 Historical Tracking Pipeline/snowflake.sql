-- ============================================================
-- 59) Snowflake — SCD Type 2 Historical Tracking Pipeline
-- Every SQL statement from the README in one file.
-- Paste the whole file into a Snowflake worksheet and run it top to bottom.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE, SCHEMA AND WAREHOUSE
-- Creates the database, a schema to hold the tables, and the compute machine
-- ============================================================

CREATE DATABASE SNOWFLAKE_SCD2_PRACTICE;

USE DATABASE SNOWFLAKE_SCD2_PRACTICE;

CREATE SCHEMA SCD2_SCHEMA;

USE SCHEMA SCD2_SCHEMA;

-- Creates the warehouse and makes it active
CREATE WAREHOUSE SCD2_WH
    WAREHOUSE_SIZE = XSMALL;

USE WAREHOUSE SCD2_WH;


-- ============================================================
-- 2. CREATE THE SOURCE TABLE
-- Holds the current customer data. This is the input.
-- ============================================================

CREATE TABLE CUSTOMER_SOURCE (
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY          VARCHAR(100),
    SALARY        NUMBER
);

-- Adds the first three customers
INSERT INTO CUSTOMER_SOURCE VALUES
(1001, 'Rahul Sharma', 'Mumbai', 75000),
(1002, 'Priya Patil', 'Pune', 62000),
(1003, 'Amit Verma', 'Delhi', 58000);

-- Checks the rows in the source table
SELECT * FROM CUSTOMER_SOURCE;


-- ============================================================
-- 3. CREATE THE SCD TYPE 2 TARGET TABLE
-- Keeps the history — every old version of a row is kept
-- ============================================================

CREATE TABLE CUSTOMER_HISTORY (
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY          VARCHAR(100),
    SALARY        NUMBER,
    VALID_FROM    TIMESTAMP,
    VALID_TO      TIMESTAMP,
    IS_CURRENT    BOOLEAN
);


-- ============================================================
-- 4. INITIAL LOAD
-- Loads the first version of every customer into the history table
-- ============================================================

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

-- Checks the history table after the first load
SELECT * FROM CUSTOMER_HISTORY ORDER BY CUSTOMER_ID;


-- ============================================================
-- 5. SIMULATE A CUSTOMER CHANGE
-- Rahul moves from Mumbai to Bengaluru and gets a new salary
-- ============================================================

UPDATE CUSTOMER_SOURCE
SET CITY = 'Bengaluru',
    SALARY = 85000
WHERE CUSTOMER_ID = 1001;

-- Checks the changed row in the source table
SELECT * FROM CUSTOMER_SOURCE WHERE CUSTOMER_ID = 1001;


-- ============================================================
-- 6. EXPIRE THE OLD RECORD
-- Close the old row by giving it an end date and turning IS_CURRENT off
-- ============================================================

UPDATE CUSTOMER_HISTORY
SET VALID_TO = CURRENT_TIMESTAMP(),
    IS_CURRENT = FALSE
WHERE CUSTOMER_ID = 1001
  AND IS_CURRENT = TRUE;

-- Checks Rahul's rows in the history table
SELECT * FROM CUSTOMER_HISTORY WHERE CUSTOMER_ID = 1001;


-- ============================================================
-- 7. INSERT THE NEW VERSION
-- Adds Rahul's new details as the current row
-- ============================================================

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


-- ============================================================
-- 8. CHECK THE HISTORY
-- Shows both the old and the new row for Rahul
-- ============================================================

SELECT * FROM CUSTOMER_HISTORY WHERE CUSTOMER_ID = 1001 ORDER BY VALID_FROM;
