-- ============================================================
-- SNOWFLAKE INCREMENTAL FILE LOAD PIPELINE
-- All the SQL for this pipeline, in README order.
--
-- How it works: upload one CSV file to the stage, then run COPY INTO.
-- Then do the same with the next file. Snowflake remembers the files
-- it already loaded, so it only loads the new ones.
--
-- Run the statements from top to bottom in a Snowflake worksheet.
-- ============================================================


-- ============================================================
-- 1. CREATE THE DATABASE
-- Makes a database for this practice project
-- ============================================================

CREATE DATABASE SNOWFLAKE_INCREMENTAL_PRACTICE;

-- Tells Snowflake which database to use
USE DATABASE SNOWFLAKE_INCREMENTAL_PRACTICE;


-- ============================================================
-- 2. CREATE THE SCHEMA
-- Makes a folder inside the database to keep things tidy
-- ============================================================

CREATE SCHEMA INCREMENTAL_SCHEMA;

-- Tells Snowflake which schema to use
USE SCHEMA INCREMENTAL_SCHEMA;


-- ============================================================
-- 3. CREATE THE WAREHOUSE
-- Makes a small machine that runs the SQL
-- ============================================================

CREATE WAREHOUSE INCREMENTAL_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Tells Snowflake which machine to use
USE WAREHOUSE INCREMENTAL_WH;


-- ============================================================
-- 4. CREATE THE TABLE
-- Makes the table that will hold the sales rows
-- ============================================================

CREATE TABLE SALES (
    ORDER_ID   NUMBER,
    ORDER_DATE DATE,
    CITY       VARCHAR(100),
    PRODUCT    VARCHAR(100),
    QUANTITY   NUMBER,
    AMOUNT     NUMBER
);

SELECT * FROM SALES;

-- Shows the columns of the table
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
-- Makes the place where the CSV files are uploaded
-- ============================================================

CREATE STAGE SALES_STAGE
    FILE_FORMAT = SALES_CSV_FORMAT;

-- Shows the stages
SHOW STAGES;


-- ============================================================
-- 7. CHECK THE STAGE AFTER UPLOADING THE FIRST FILE
-- Upload sales_01_initial.csv to SALES_STAGE first. Then run this
-- ============================================================

LIST @SALES_STAGE;


-- ============================================================
-- 8. LOAD THE FIRST FILE
-- This loads sales_01_initial.csv. The table now has 3 rows
-- ============================================================

COPY INTO SALES
FROM @SALES_STAGE;

-- Shows all the rows in the table
SELECT * FROM SALES ORDER BY ORDER_ID;

-- Counts the rows. You should get 3
SELECT COUNT(*) FROM SALES;


-- ============================================================
-- 9. CHECK THE STAGE AFTER UPLOADING THE SECOND FILE
-- Do not delete the first file. Upload sales_02_incremental.csv
-- next to it. Then run this
-- ============================================================

LIST @SALES_STAGE;


-- ============================================================
-- 10. LOAD THE SECOND FILE — THE SAME COPY INTO AGAIN
-- This is the most important step of the whole pipeline
-- ============================================================

-- Same command as Step 8.
-- Snowflake remembers the files it already loaded, so it skips
-- sales_01_initial.csv and loads only the new file.
-- Run this same COPY INTO again and it loads 0 new rows.
-- (To load the same file again on purpose you would need FORCE = TRUE.
--  This pipeline does not use it.)
COPY INTO SALES
FROM @SALES_STAGE;

-- Counts the rows. You should get 6. Not 3 and not 9
SELECT COUNT(*) FROM SALES;


-- ============================================================
-- 11. CHECK THE DATA
-- Shows the rows. The order IDs run from 4001 to 4006
-- ============================================================

SELECT * FROM SALES ORDER BY ORDER_ID;


-- ============================================================
-- 12. LOAD THE THIRD FILE
-- Upload sales_03_incremental.csv to the stage. Then run the
-- same COPY INTO once more. Only the new file is loaded
-- ============================================================

COPY INTO SALES
FROM @SALES_STAGE;

-- Counts the rows. You should get 9
SELECT COUNT(*) FROM SALES;


-- ============================================================
-- 13. SEE WHICH FILES WERE LOADED
-- Shows the name, status and row count of every file Snowflake
-- loaded into this table in the last day
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
-- The README runs the same command one more time to prove the point:
-- Snowflake skips a file it already loaded, so this run adds
-- nothing new
-- ============================================================

COPY INTO SALES
FROM @SALES_STAGE;
