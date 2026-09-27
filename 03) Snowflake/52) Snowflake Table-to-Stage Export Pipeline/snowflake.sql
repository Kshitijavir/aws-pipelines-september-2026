-- ============================================================
-- 52) Snowflake - Table-to-Stage Export Pipeline
-- All the SQL for this pipeline, in the same order as the README.
-- Paste the whole file into a Snowflake worksheet.
--
-- This pipeline sends data OUT of Snowflake. The command that does
-- it is COPY INTO @stage, and you are meant to run it yourself.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- This makes a database for this practice
-- ============================================================

CREATE DATABASE SNOWFLAKE_UNLOAD_PRACTICE;

-- Use this database from now on
USE DATABASE SNOWFLAKE_UNLOAD_PRACTICE;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- This makes a folder inside the database
-- ============================================================

CREATE SCHEMA EXPORT_SCHEMA;

-- Use this schema from now on
USE SCHEMA EXPORT_SCHEMA;


-- ============================================================
-- STEP 3. CREATE WAREHOUSE
-- This makes a small machine that runs the SQL
-- ============================================================

CREATE WAREHOUSE EXPORT_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Use this machine to run the SQL
USE WAREHOUSE EXPORT_WH;


-- ============================================================
-- STEP 4. CREATE THE SOURCE TABLE
-- This makes the table that holds the data we send out
-- ============================================================

CREATE TABLE CUSTOMER_EXPORT (
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  VARCHAR(100),
    EMAIL          VARCHAR(200),
    CITY           VARCHAR(100),
    COUNTRY        VARCHAR(50),
    TOTAL_PURCHASE NUMBER
);

-- Shows the table now. It is empty.
SELECT * FROM CUSTOMER_EXPORT;


-- ============================================================
-- STEP 5. INSERT DATA
-- Adds 5 rows to the table
-- ============================================================

INSERT INTO CUSTOMER_EXPORT VALUES
(3001, 'Rahul Sharma', 'rahul@example.com', 'Mumbai', 'India', 75000),
(3002, 'Priya Patil', 'priya@example.com', 'Pune', 'India', 62000),
(3003, 'Amit Verma', 'amit@example.com', 'Delhi', 'India', 58000),
(3004, 'Sneha Joshi', 'sneha@example.com', 'Bengaluru', 'India', 91000),
(3005, 'Vikas Kumar', 'vikas@example.com', 'Hyderabad', 'India', 67000);

-- Shows the 5 rows
SELECT *
FROM CUSTOMER_EXPORT;


-- ============================================================
-- STEP 6. CREATE THE EXPORT FILE FORMAT
-- This tells Snowflake how to write the CSV file
-- ============================================================

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT
TYPE = 'CSV'
FIELD_DELIMITER = ','
COMPRESSION = 'NONE'
FIELD_OPTIONALLY_ENCLOSED_BY = '"';


-- ============================================================
-- STEP 7. CREATE THE INTERNAL STAGE
-- This makes the stage that receives the file
-- ============================================================

CREATE STAGE CUSTOMER_EXPORT_STAGE
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT;

-- Shows the stages you have
SHOW STAGES;


-- ============================================================
-- STEP 8. MAIN EXPORT COMMAND
-- This sends the data out of Snowflake into the stage
-- ============================================================

COPY INTO @CUSTOMER_EXPORT_STAGE
FROM CUSTOMER_EXPORT;


-- ============================================================
-- STEP 9. CHECK THE EXPORTED FILE
-- Shows the files now in the stage
-- ============================================================

LIST @CUSTOMER_EXPORT_STAGE;
