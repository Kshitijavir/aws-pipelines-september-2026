-- ============================================================
-- SNOWFLAKE INCREMENTAL FILE LOAD PIPELINE
-- Every SQL statement for this pipeline, in README order.
--
-- How it works: upload one CSV file to the stage, run COPY INTO,
-- then do the same with the next file. Snowflake remembers the
-- files it has already loaded, so it only picks up the new ones.
--
-- Run the statements from top to bottom in a Snowflake worksheet.
-- ============================================================


-- ============================================================
-- 1. CREATE THE DATABASE
-- Makes a separate database for this practice project
-- ============================================================

CREATE DATABASE SNOWFLAKE_INCREMENTAL_PRACTICE;

-- Selects the database for the rest of the work
USE DATABASE SNOWFLAKE_INCREMENTAL_PRACTICE;


-- ============================================================
-- 2. CREATE THE SCHEMA
-- Makes a folder inside the database to keep the objects tidy
-- ============================================================

CREATE SCHEMA INCREMENTAL_SCHEMA;

-- Selects the schema for the rest of the work
USE SCHEMA INCREMENTAL_SCHEMA;


-- ============================================================
-- 3. CREATE THE WAREHOUSE
-- Makes a small machine that runs the SQL
-- ============================================================

CREATE WAREHOUSE INCREMENTAL_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Selects the machine used to run the queries
USE WAREHOUSE INCREMENTAL_WH;


-- ============================================================
-- 4. CREATE THE TABLE
-- Makes the table that will collect the sales rows
-- ============================================================

CREATE TABLE SALES (
    ORDER_ID   NUMBER,
    ORDER_DATE DATE,
    CITY       VARCHAR(100),
    PRODUCT    VARCHAR(100),
    QUANTITY   NUMBER,
    AMOUNT     NUMBER
);

-- Shows the table columns
DESC TABLE SALES;


-- ============================================================
-- 5. CREATE THE FILE FORMAT
-- Tells Snowflake how to read the CSV files
-- ============================================================

CREATE FILE FORMAT SALES_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'YYYY-MM-DD';


-- ============================================================
-- 6. CREATE THE STAGE
-- Makes the landing spot where the CSV files are uploaded
-- ============================================================

CREATE STAGE SALES_STAGE
    FILE_FORMAT = SALES_CSV_FORMAT;

-- Shows the stages
SHOW STAGES;


-- ============================================================
-- 7. CHECK THE STAGE AFTER UPLOADING THE FIRST FILE
-- Upload sales_01_initial.csv to SALES_STAGE first, then run this
-- ============================================================

LIST @SALES_STAGE;


-- ============================================================
-- 8. LOAD THE FIRST FILE
-- Loads sales_01_initial.csv, so the table now holds 3 rows
-- ============================================================

COPY INTO SALES
FROM @SALES_STAGE;

-- Shows all the rows in the table
SELECT * FROM SALES ORDER BY ORDER_ID;

-- Counts the rows. You should get 3
SELECT COUNT(*) FROM SALES;


-- ============================================================
-- 9. CHECK THE STAGE AFTER UPLOADING THE SECOND FILE
-- Do NOT delete the first file. Upload sales_02_incremental.csv
-- next to it, then run this
-- ============================================================

LIST @SALES_STAGE;


-- ============================================================
-- 10. LOAD THE SECOND FILE — THE SAME COPY INTO AGAIN
-- This is the most important step of the whole pipeline
-- ============================================================

-- Same command as Step 8.
-- Snowflake remembers the files it has already loaded, so
-- sales_01_initial.csv is skipped and only the new file is loaded.
-- Run this same COPY INTO a second time and it loads 0 new rows.
-- (To load a file you have already loaded on purpose, you would need
--  FORCE = TRUE. This pipeline does not use it.)
COPY INTO SALES
FROM @SALES_STAGE;

-- Counts the rows. You should get 6, not 3 and not 9
SELECT COUNT(*) FROM SALES;


-- ============================================================
-- 11. CHECK THE DATA
-- Shows the rows. The order IDs run from 4001 to 4006
-- ============================================================

SELECT * FROM SALES ORDER BY ORDER_ID;


-- ============================================================
-- 12. LOAD THE THIRD FILE
-- Upload sales_03_incremental.csv to the stage, then run the
-- same COPY INTO once more. Only the new file is loaded
-- ============================================================

COPY INTO SALES
FROM @SALES_STAGE;

-- Counts the rows. You should get 9
SELECT COUNT(*) FROM SALES;


-- ============================================================
-- 13. SEE WHICH FILES WERE LOADED
-- Shows the name, status and row count of every file Snowflake
-- has loaded into this table in the last day
-- ============================================================

SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    LAST_LOAD_TIME
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'SNOWFLAKE_INCREMENTAL_PRACTICE.INCREMENTAL_SCHEMA.SALES',
        START_TIME => DATEADD(DAY, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME;


-- ============================================================
-- 14. THE KEY CONCEPT
-- The README shows the same command one more time to make the
-- point clear: Snowflake skips a file it has already loaded,
-- so this run adds nothing new
-- ============================================================

COPY INTO SALES
FROM @SALES_STAGE;
