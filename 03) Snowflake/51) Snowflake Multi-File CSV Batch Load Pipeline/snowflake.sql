-- ============================================================
-- 51) Snowflake - Multi-File CSV Batch Load Pipeline
-- Every SQL statement for this pipeline, in README order.
-- Paste the whole file into a Snowflake worksheet and run it.
--
-- One COPY INTO loads all 5 CSV files, which is 15 rows.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- Creates the database that holds everything for this pipeline
-- ============================================================

CREATE DATABASE SNOWFLAKE_MULTI_FILE_PRACTICE;

-- Selects the database for the remaining operations
USE DATABASE SNOWFLAKE_MULTI_FILE_PRACTICE;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- Creates a folder that keeps this pipeline's objects together
-- ============================================================

CREATE SCHEMA MULTI_FILE_SCHEMA;

-- Selects the schema for the remaining operations
USE SCHEMA MULTI_FILE_SCHEMA;


-- ============================================================
-- STEP 3. CREATE WAREHOUSE
-- Creates the machine that runs the load
-- ============================================================

CREATE WAREHOUSE MULTI_FILE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Selects the warehouse used to execute queries
USE WAREHOUSE MULTI_FILE_WH;


-- ============================================================
-- STEP 4. CREATE TABLE
-- Creates the table where all 15 rows end up
-- Note the extra DEPARTMENT column that Pipeline 50 did not have
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

-- Displays the table structure and column definitions
DESC TABLE EMPLOYEE_MULTI;


-- ============================================================
-- STEP 5. CREATE FILE FORMAT
-- Tells Snowflake how to read the CSV files
-- One format is enough, because all five files look the same
-- ============================================================

CREATE FILE FORMAT EMPLOYEE_MULTI_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'YYYY-MM-DD';

-- Displays the file format details
DESC FILE FORMAT EMPLOYEE_MULTI_CSV_FORMAT;


-- ============================================================
-- STEP 6. CREATE INTERNAL STAGE
-- Creates the stage that holds all five files at the same time
-- ============================================================

CREATE STAGE EMPLOYEE_MULTI_STAGE
    FILE_FORMAT = EMPLOYEE_MULTI_CSV_FORMAT;

-- Displays the available stages
SHOW STAGES;


-- ============================================================
-- STEP 7. UPLOAD ALL 5 CSV FILES
-- This step is done in Snowsight, not with SQL:
-- Data -> Databases -> SNOWFLAKE_MULTI_FILE_PRACTICE ->
-- MULTI_FILE_SCHEMA -> Stages -> EMPLOYEE_MULTI_STAGE -> Upload
--
-- Upload all five files into the stage ROOT, not into a
-- sub-folder, or the COPY INTO in Step 9 will not find them.
-- ============================================================


-- ============================================================
-- STEP 8. VERIFY ALL 5 FILES
-- Lists the files currently sitting in the stage
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
-- Shows all 15 rows and then counts them
-- ============================================================

SELECT * FROM EMPLOYEE_MULTI ORDER BY EMPLOYEE_ID;

SELECT COUNT(*) FROM EMPLOYEE_MULTI;


-- ============================================================
-- STEP 11. WHICH FILE DID EACH ROW COME FROM?
-- The metadata columns tell you the source file of every row
-- ============================================================

SELECT
    METADATA$FILENAME        AS SOURCE_FILE,
    METADATA$FILE_ROW_NUMBER AS ROW_IN_FILE,
    EMPLOYEE_ID,
    EMPLOYEE_NAME
FROM EMPLOYEE_MULTI
ORDER BY SOURCE_FILE, EMPLOYEE_ID;

-- Reads the same details straight from the stage
SELECT METADATA$FILENAME, METADATA$FILE_ROW_NUMBER
FROM @EMPLOYEE_MULTI_STAGE;


-- ============================================================
-- STEP 12. CHECK THE COPY HISTORY
-- Shows what was loaded, from which file, and if any rows failed
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
