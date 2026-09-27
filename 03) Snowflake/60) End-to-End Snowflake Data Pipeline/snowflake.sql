-- ============================================================
-- 60) End-to-End Snowflake Data Pipeline
-- All the SQL from the README, in the same order.
-- Paste this whole file into a Snowflake worksheet and run it.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- Makes the database that holds everything below
-- ============================================================

CREATE DATABASE SNOWFLAKE_END_TO_END_PRACTICE;


-- Use this database from now on
USE DATABASE SNOWFLAKE_END_TO_END_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Makes a folder inside the database to hold the objects
-- ============================================================

CREATE SCHEMA E2E_SCHEMA;


-- Use this schema from now on
USE SCHEMA E2E_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Makes the machine that runs the SQL and loads the data
-- ============================================================

CREATE WAREHOUSE E2E_WH
    WAREHOUSE_SIZE = XSMALL;


-- Use this warehouse to run the SQL
USE WAREHOUSE E2E_WH;


-- ============================================================
-- 4. CREATE THE RAW TABLE
-- Holds the CSV data exactly as it comes from the file
-- ============================================================

CREATE TABLE CUSTOMER_RAW (
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY          VARCHAR(100),
    SALARY        NUMBER
);

SELECT * FROM CUSTOMER_RAW;


-- ============================================================
-- 5. CREATE THE FILE FORMAT
-- Tells Snowflake how to read the CSV file
-- ============================================================

CREATE FILE FORMAT CUSTOMER_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';


-- ============================================================
-- 6. CREATE THE STAGE
-- The landing area that holds the CSV file you upload
-- ============================================================

CREATE STAGE CUSTOMER_STAGE
    FILE_FORMAT = CUSTOMER_CSV_FORMAT;


-- ============================================================
-- 7. CREATE THE FINAL TABLE
-- Holds the clean data with the salary category column
-- ============================================================

CREATE TABLE CUSTOMER_FINAL (
    CUSTOMER_ID     NUMBER,
    CUSTOMER_NAME   VARCHAR(100),
    CITY            VARCHAR(100),
    SALARY          NUMBER,
    SALARY_CATEGORY VARCHAR(20)
);

SELECT * FROM CUSTOMER_FINAL;


-- ============================================================
-- 8. CHECK THE UPLOADED FILE
-- Upload customer.csv to CUSTOMER_STAGE in Snowsight first.
-- This then lists the files in the stage
-- ============================================================

LIST @CUSTOMER_STAGE;


-- ============================================================
-- 9. LOAD THE CSV INTO THE RAW TABLE
-- This loads the CSV into the raw table
-- ============================================================

COPY INTO CUSTOMER_RAW
FROM @CUSTOMER_STAGE;


-- Checks the rows in the raw table
SELECT * FROM CUSTOMER_RAW;


-- ============================================================
-- 10. TRANSFORM THE DATA
-- Copies the raw rows into the final table.
-- Makes the names and cities use capital letters, and sets the salary category.
-- ============================================================

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


-- ============================================================
-- 11. CHECK THE FINAL TABLE
-- Shows the clean rows with their salary category
-- ============================================================

SELECT * FROM CUSTOMER_FINAL ORDER BY CUSTOMER_ID;
