-- ============================================================
-- 51) Snowflake - Multi-File CSV Batch Load Pipeline
-- Folder 02 - Multiple CSV to Multiple Tables
-- All the SQL for this pipeline, in README order.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- 4 CSV files go into 4 stages, and each stage loads into its own table.
-- That is 4 COPY INTO statements, 3 rows per file = 12 rows in total.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- Makes the database that holds everything for this pipeline
-- ============================================================

CREATE DATABASE MULTI_TABLE_LOAD_DB;

-- Uses this database for the next statements
USE DATABASE MULTI_TABLE_LOAD_DB;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- Makes a folder that keeps this pipeline's objects together
-- ============================================================

CREATE SCHEMA EMPLOYEE_LOAD_SCHEMA;

-- Uses this schema for the next statements
USE SCHEMA EMPLOYEE_LOAD_SCHEMA;


-- ============================================================
-- STEP 3. CREATE WAREHOUSE
-- Makes the machine that runs the loads
-- ============================================================

CREATE WAREHOUSE EMPLOYEE_LOAD_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Uses this warehouse to run the queries
USE WAREHOUSE EMPLOYEE_LOAD_WH;


-- ============================================================
-- STEP 4. CREATE THE FOUR TABLES
-- One table for each file.
-- All four tables look the same, because all four files have
-- the same columns
-- ============================================================

CREATE TABLE EMPLOYEE_DATA_1 (
    EMPLOYEE_ID   NUMBER(10,0),
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    COUNTRY       VARCHAR(50),
    DEPARTMENT    VARCHAR(50),
    JOINING_DATE  DATE,
    SALARY        NUMBER(12,2)
);

SELECT * FROM EMPLOYEE_DATA_1;


CREATE TABLE EMPLOYEE_DATA_2 (
    EMPLOYEE_ID   NUMBER(10,0),
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    COUNTRY       VARCHAR(50),
    DEPARTMENT    VARCHAR(50),
    JOINING_DATE  DATE,
    SALARY        NUMBER(12,2)
);

SELECT * FROM EMPLOYEE_DATA_2;


CREATE TABLE EMPLOYEE_DATA_3 (
    EMPLOYEE_ID   NUMBER(10,0),
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    COUNTRY       VARCHAR(50),
    DEPARTMENT    VARCHAR(50),
    JOINING_DATE  DATE,
    SALARY        NUMBER(12,2)
);

SELECT * FROM EMPLOYEE_DATA_3;


CREATE TABLE EMPLOYEE_DATA_4 (
    EMPLOYEE_ID   NUMBER(10,0),
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    COUNTRY       VARCHAR(50),
    DEPARTMENT    VARCHAR(50),
    JOINING_DATE  DATE,
    SALARY        NUMBER(12,2)
);

SELECT * FROM EMPLOYEE_DATA_4;


-- ============================================================
-- STEP 5. CREATE FILE FORMAT
-- Tells Snowflake how to read the CSV files
-- One format is enough. All four files look the same
-- ============================================================

CREATE FILE FORMAT EMPLOYEE_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'YYYY-MM-DD';

-- Shows the details of the file format
DESC FILE FORMAT EMPLOYEE_CSV_FORMAT;


-- ============================================================
-- STEP 6. CREATE THE FOUR INTERNAL STAGES
-- One stage for each file, so the files never mix
-- ============================================================

CREATE STAGE EMPLOYEE_STAGE_1
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;


CREATE STAGE EMPLOYEE_STAGE_2
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;


CREATE STAGE EMPLOYEE_STAGE_3
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;


CREATE STAGE EMPLOYEE_STAGE_4
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;

-- Shows the stages
SHOW STAGES;


-- ============================================================
-- STEP 7. UPLOAD THE FOUR CSV FILES
-- Do this step in Snowsight. There is no SQL here:
-- Data -> Databases -> MULTI_TABLE_LOAD_DB -> EMPLOYEE_LOAD_SCHEMA ->
-- Stages -> <stage name> -> Upload
--
-- Put ONE file in each stage, and put it in the stage ROOT:
--   employees_01.csv -> EMPLOYEE_STAGE_1
--   employees_02.csv -> EMPLOYEE_STAGE_2
--   employees_03.csv -> EMPLOYEE_STAGE_3
--   employees_04.csv -> EMPLOYEE_STAGE_4
--
-- If you upload into a sub-folder, the COPY INTO in Step 9 will not find it.
-- If you upload into the wrong stage, the wrong table gets the rows.
-- ============================================================


-- ============================================================
-- STEP 8. VERIFY ALL 4 FILES
-- Lists the files that are now in each stage.
-- Each LIST should show exactly one file
-- ============================================================

LIST @EMPLOYEE_STAGE_1;

LIST @EMPLOYEE_STAGE_2;

LIST @EMPLOYEE_STAGE_3;

LIST @EMPLOYEE_STAGE_4;


-- ============================================================
-- STEP 9. LOAD EACH STAGE INTO ITS OWN TABLE
-- Four short statements. Only the stage name and the table
-- name change from one statement to the next
-- ============================================================

COPY INTO EMPLOYEE_DATA_1
FROM @EMPLOYEE_STAGE_1
FILE_FORMAT = (
    FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT'
);


COPY INTO EMPLOYEE_DATA_2
FROM @EMPLOYEE_STAGE_2
FILE_FORMAT = (
    FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT'
);


COPY INTO EMPLOYEE_DATA_3
FROM @EMPLOYEE_STAGE_3
FILE_FORMAT = (
    FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT'
);


COPY INTO EMPLOYEE_DATA_4
FROM @EMPLOYEE_STAGE_4
FILE_FORMAT = (
    FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT'
);


-- ============================================================
-- STEP 10. VERIFY THE DATA
-- Counts the rows in each table. Every table should show 3
-- ============================================================

SELECT COUNT(*) FROM EMPLOYEE_DATA_1;

SELECT COUNT(*) FROM EMPLOYEE_DATA_2;

SELECT COUNT(*) FROM EMPLOYEE_DATA_3;

SELECT COUNT(*) FROM EMPLOYEE_DATA_4;


-- ============================================================
-- STEP 11. CHECK THE COPY HISTORY
-- Shows what was loaded into each table, from which file,
-- and any rows that failed.
-- Each query returns one row, because each table got one file
-- ============================================================

SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    ROW_PARSED,
    FIRST_ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_DATA_1',
        START_TIME => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME;


SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    ROW_PARSED,
    FIRST_ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_DATA_2',
        START_TIME => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME;


SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    ROW_PARSED,
    FIRST_ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_DATA_3',
        START_TIME => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME;


SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    ROW_PARSED,
    FIRST_ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_DATA_4',
        START_TIME => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME;
