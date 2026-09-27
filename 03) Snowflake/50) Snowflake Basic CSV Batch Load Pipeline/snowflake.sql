-- ============================================================
-- 50) Snowflake - Basic CSV Batch Load Pipeline
-- Every SQL statement for this pipeline, in the same order as the README.
-- Paste this whole file into a Snowflake worksheet.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- Creates the big box that holds everything below
-- ============================================================

CREATE DATABASE SNOWFLAKE_PRACTICE;


-- Selects the database for the remaining operations
USE DATABASE SNOWFLAKE_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Creates a folder inside the database to keep the objects together
-- ============================================================

CREATE SCHEMA EMPLOYEE_SCHEMA;


-- Selects the schema for the remaining operations
USE SCHEMA EMPLOYEE_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Creates the machine that runs the SQL and does the loading
-- ============================================================

CREATE WAREHOUSE PRACTICE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;


-- Selects the warehouse used to run the queries
USE WAREHOUSE PRACTICE_WH;


-- ============================================================
-- 4. CREATE TABLE
-- Creates the table where the CSV rows will end up
-- ============================================================

CREATE TABLE EMPLOYEE (
    EMPLOYEE_ID   NUMBER(10,0),
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    COUNTRY       VARCHAR(50),
    JOINING_DATE  DATE,
    SALARY        NUMBER(12,2)
);


-- Displays the table structure and the column definitions
DESC TABLE EMPLOYEE;


-- ============================================================
-- 5. CREATE FILE FORMAT
-- Tells Snowflake how to read the CSV
-- ============================================================

CREATE FILE FORMAT EMPLOYEE_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'YYYY-MM-DD';


-- Displays the reading rules written in the file format
DESC FILE FORMAT EMPLOYEE_CSV_FORMAT;


-- ============================================================
-- 6. CREATE INTERNAL STAGE
-- Creates a landing spot for the file inside Snowflake
-- ============================================================

CREATE STAGE EMPLOYEE_STAGE
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;


-- Displays the available stages
SHOW STAGES;


-- ============================================================
-- 7. UPLOAD THE CSV AND LIST THE STAGE
-- The upload itself is done by hand in Snowsight, not with SQL
-- ============================================================

-- Shows the file that is now sitting in the stage
LIST @EMPLOYEE_STAGE;


-- ============================================================
-- 8. LOAD THE CSV INTO THE TABLE
-- Moves the file's data from the stage into the EMPLOYEE table
-- ============================================================

COPY INTO EMPLOYEE
FROM @EMPLOYEE_STAGE
FILE_FORMAT = (FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT');


-- read the file and show errors, but save no rows
COPY INTO EMPLOYEE
FROM @EMPLOYEE_STAGE
VALIDATION_MODE = RETURN_ERRORS;

-- load the rows, and delete the file from the stage at the same time
COPY INTO EMPLOYEE
FROM @EMPLOYEE_STAGE
FILE_FORMAT = (FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT')
PURGE = TRUE;


-- ============================================================
-- 9. VERIFY THE LOAD
-- Shows the rows and the row count saved in the table
-- ============================================================

SELECT * FROM EMPLOYEE;


SELECT COUNT(*) FROM EMPLOYEE;


-- ============================================================
-- 10. CHECK THE STAGE STILL HOLDS THE FILE
-- COPY INTO never deletes the staged file, so it should still be there
-- ============================================================

LIST @EMPLOYEE_STAGE;


-- ============================================================
-- 11. CHECK THE LOAD HISTORY
-- Shows every COPY INTO recorded for this table in the last day
-- ============================================================

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'SNOWFLAKE_PRACTICE.EMPLOYEE_SCHEMA.EMPLOYEE',
        START_TIME => DATEADD(DAY, -1, CURRENT_TIMESTAMP())
    )
);


-- ============================================================
-- 12. TROUBLESHOOTING A FAILED LOAD
-- Reads the file and shows the errors, but saves no rows
-- ============================================================

COPY INTO EMPLOYEE
FROM @EMPLOYEE_STAGE
VALIDATION_MODE = RETURN_ERRORS;
