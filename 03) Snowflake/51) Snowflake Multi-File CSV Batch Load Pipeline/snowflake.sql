-- ============================================================
-- 51) Snowflake - Multi-File CSV Batch Load Pipeline
-- All the SQL for this pipeline, in README order.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- One COPY INTO loads all 5 CSV files. That is 15 rows.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- Makes the database that holds everything for this pipeline
-- ============================================================

CREATE DATABASE SNOWFLAKE_MULTI_FILE_PRACTICE;

-- Uses this database for the next statements
USE DATABASE SNOWFLAKE_MULTI_FILE_PRACTICE;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- Makes a folder that keeps this pipeline's objects together
-- ============================================================

CREATE SCHEMA MULTI_FILE_SCHEMA;

-- Uses this schema for the next statements
USE SCHEMA MULTI_FILE_SCHEMA;


-- ============================================================
-- STEP 3. CREATE WAREHOUSE
-- Makes the machine that runs the load
-- ============================================================

CREATE WAREHOUSE MULTI_FILE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Uses this warehouse to run the queries
USE WAREHOUSE MULTI_FILE_WH;


-- ============================================================
-- STEP 4. CREATE TABLE
-- Makes the table where all 15 rows go
-- The DEPARTMENT column is new. Pipeline 50 did not have it
-- ============================================================

CREATE TABLE EMPLOYEE_MULTI (
    EMPLOYEE_ID   NUMBER(10,0),
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    COUNTRY       VARCHAR(50),
    DEPARTMENT    VARCHAR(50),
    JOINING_DATE  DATE,
    SALARY        NUMBER(12,2)
);

SELECT * FROM EMPLOYEE_MULTI;

-- Shows the columns of the table
DESC TABLE EMPLOYEE_MULTI;


-- ============================================================
-- STEP 5. CREATE FILE FORMAT
-- Tells Snowflake how to read the CSV files
-- One format is enough. All five files look the same
-- ============================================================

CREATE FILE FORMAT EMPLOYEE_MULTI_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'YYYY-MM-DD';

-- Shows the details of the file format
DESC FILE FORMAT EMPLOYEE_MULTI_CSV_FORMAT;


-- ============================================================
-- STEP 6. CREATE INTERNAL STAGE
-- Makes the stage that holds all five files
-- ============================================================

CREATE STAGE EMPLOYEE_MULTI_STAGE
    FILE_FORMAT = EMPLOYEE_MULTI_CSV_FORMAT;

-- Shows the stages
SHOW STAGES;


-- ============================================================
-- STEP 7. UPLOAD ALL 5 CSV FILES
-- Do this step in Snowsight. There is no SQL here:
-- Data -> Databases -> SNOWFLAKE_MULTI_FILE_PRACTICE ->
-- MULTI_FILE_SCHEMA -> Stages -> EMPLOYEE_MULTI_STAGE -> Upload
--
-- Put all five files in the stage ROOT, not in a sub-folder.
-- If you use a sub-folder, the COPY INTO in Step 9 will not find them.
-- ============================================================


-- ============================================================
-- STEP 8. VERIFY ALL 5 FILES
-- Lists the files that are now in the stage
-- ============================================================

LIST @EMPLOYEE_MULTI_STAGE;


-- ============================================================
-- STEP 9. LOAD ALL 5 FILES
-- One COPY INTO reads every file in the stage
-- ============================================================

COPY INTO EMPLOYEE_MULTI
FROM @EMPLOYEE_MULTI_STAGE
FILE_FORMAT = (
    FORMAT_NAME = 'EMPLOYEE_MULTI_CSV_FORMAT'
);


-- ============================================================
-- STEP 10. VERIFY THE DATA
-- Shows all 15 rows, then counts them
-- ============================================================

SELECT * FROM EMPLOYEE_MULTI ORDER BY EMPLOYEE_ID;

SELECT COUNT(*) FROM EMPLOYEE_MULTI;


-- ============================================================
-- STEP 11. WHICH FILE DID EACH ROW COME FROM?
-- The metadata columns tell you which file each row came from
-- ============================================================

SELECT
    METADATA$FILENAME        AS SOURCE_FILE,
    METADATA$FILE_ROW_NUMBER AS ROW_IN_FILE,
    EMPLOYEE_ID,
    EMPLOYEE_NAME
FROM EMPLOYEE_MULTI
ORDER BY SOURCE_FILE, EMPLOYEE_ID;

-- Reads the same details from the stage
SELECT METADATA$FILENAME, METADATA$FILE_ROW_NUMBER
FROM @EMPLOYEE_MULTI_STAGE;


-- ============================================================
-- STEP 12. CHECK THE COPY HISTORY
-- Shows what was loaded, from which file, and any rows that failed
-- ============================================================

SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    ROW_PARSED,
    FIRST_ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'SNOWFLAKE_MULTI_FILE_PRACTICE.MULTI_FILE_SCHEMA.EMPLOYEE_MULTI',
        START_TIME => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME;
