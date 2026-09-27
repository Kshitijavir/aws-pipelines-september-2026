-- ============================================================
-- 52) Snowflake - Table-to-Stage Export Pipeline
-- Every SQL statement for this pipeline, in README order.
-- Paste the whole file into a Snowflake worksheet and run it.
--
-- This pipeline EXPORTS data out of Snowflake. The command that
-- does the export is COPY INTO @stage, and you are meant to run it.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- Creates a separate database for this practice project
-- ============================================================

CREATE DATABASE SNOWFLAKE_UNLOAD_PRACTICE;

-- Selects the database for the remaining operations
USE DATABASE SNOWFLAKE_UNLOAD_PRACTICE;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- Creates a folder inside the database to keep the objects tidy
-- ============================================================

CREATE SCHEMA EXPORT_SCHEMA;

-- Selects the schema for the remaining operations
USE SCHEMA EXPORT_SCHEMA;


-- ============================================================
-- STEP 3. CREATE WAREHOUSE
-- Creates a small machine that runs the SQL
-- ============================================================

CREATE WAREHOUSE EXPORT_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Selects the warehouse used to execute queries
USE WAREHOUSE EXPORT_WH;


-- ============================================================
-- STEP 4. CREATE THE SOURCE TABLE
-- Creates the table that holds the data we want to send out
-- ============================================================

CREATE TABLE CUSTOMER_EXPORT (
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  VARCHAR(100),
    EMAIL          VARCHAR(200),
    CITY           VARCHAR(100),
    COUNTRY        VARCHAR(50),
    TOTAL_PURCHASE NUMBER
);


-- ============================================================
-- STEP 5. INSERT DATA
-- Puts 5 sample customer rows into the source table
-- ============================================================

INSERT INTO CUSTOMER_EXPORT VALUES
(3001, 'Rahul Sharma', 'rahul@example.com', 'Mumbai', 'India', 75000),
(3002, 'Priya Patil', 'priya@example.com', 'Pune', 'India', 62000),
(3003, 'Amit Verma', 'amit@example.com', 'Delhi', 'India', 58000),
(3004, 'Sneha Joshi', 'sneha@example.com', 'Bengaluru', 'India', 91000),
(3005, 'Vikas Kumar', 'vikas@example.com', 'Hyderabad', 'India', 67000);

-- Shows the 5 rows that were inserted
SELECT *
FROM CUSTOMER_EXPORT;


-- ============================================================
-- STEP 6. CREATE THE EXPORT FILE FORMAT
-- Tells Snowflake how to write the exported CSV file
-- ============================================================

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT
TYPE = 'CSV'
FIELD_DELIMITER = ','
COMPRESSION = 'NONE'
FIELD_OPTIONALLY_ENCLOSED_BY = '"';


-- ============================================================
-- STEP 7. CREATE THE INTERNAL STAGE
-- Creates the stage that receives the exported file
-- ============================================================

CREATE STAGE CUSTOMER_EXPORT_STAGE
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT;

-- Displays the available stages
SHOW STAGES;


-- ============================================================
-- STEP 8. MAIN EXPORT COMMAND
-- Sends the data out of Snowflake into the stage
-- ============================================================

COPY INTO @CUSTOMER_EXPORT_STAGE
FROM CUSTOMER_EXPORT;


-- ============================================================
-- STEP 9. CHECK THE EXPORTED FILE
-- Lists the files that are now sitting in the stage
-- ============================================================

LIST @CUSTOMER_EXPORT_STAGE;


-- ============================================================
-- STEP 11. EXPORT WITH COLUMN HEADERS
-- Same export, but the first row of the file holds the column names
-- ============================================================

COPY INTO @CUSTOMER_EXPORT_STAGE
FROM CUSTOMER_EXPORT
HEADER = TRUE;

-- If you get "Files already existing at the unload destination",
-- empty the stage first ...
REMOVE @CUSTOMER_EXPORT_STAGE;

-- ... then run the export again
COPY INTO @CUSTOMER_EXPORT_STAGE
FROM CUSTOMER_EXPORT
HEADER = TRUE;

-- Lists the files in the stage, so you can pick the new one
LIST @CUSTOMER_EXPORT_STAGE;


-- ============================================================
-- STEP 12. EXPORT ONLY SELECTED COLUMNS
-- Exports 4 of the 6 columns instead of the whole table
-- ============================================================

COPY INTO @CUSTOMER_EXPORT_STAGE
FROM (
    SELECT
        CUSTOMER_ID,
        CUSTOMER_NAME,
        CITY,
        TOTAL_PURCHASE
    FROM CUSTOMER_EXPORT
)
HEADER = TRUE;


-- ============================================================
-- STEP 13. EXPORT FILTERED DATA
-- Exports only the rows where TOTAL_PURCHASE is above 65000
-- ============================================================

COPY INTO @CUSTOMER_EXPORT_STAGE
FROM (
    SELECT
        CUSTOMER_ID,
        CUSTOMER_NAME,
        CITY,
        TOTAL_PURCHASE
    FROM CUSTOMER_EXPORT
    WHERE TOTAL_PURCHASE > 65000
)
HEADER = TRUE;
