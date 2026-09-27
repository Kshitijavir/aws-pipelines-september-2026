-- ============================================================
-- 50) Snowflake - Basic CSV Batch Load Pipeline
-- All the SQL for this pipeline, in the same order as the README.
-- Paste the whole file into a Snowflake worksheet.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- This makes the big box that holds everything
-- ============================================================

CREATE DATABASE SNOWFLAKE_PRACTICE;


-- Use this database from now on
USE DATABASE SNOWFLAKE_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- This makes a folder inside the database
-- ============================================================

CREATE SCHEMA EMPLOYEE_SCHEMA;


-- Use this schema from now on
USE SCHEMA EMPLOYEE_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- This makes the machine that runs the SQL
-- ============================================================

CREATE WAREHOUSE PRACTICE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;


-- Use this machine to run the SQL
USE WAREHOUSE PRACTICE_WH;


-- ============================================================
-- 4. CREATE TABLE
-- This makes the table that will hold the rows
-- ============================================================

CREATE TABLE EMPLOYEE (
    EMPLOYEE_ID   NUMBER(10,0),
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    COUNTRY       VARCHAR(50),
    JOINING_DATE  DATE,
    SALARY        NUMBER(12,2)
);


-- Shows the table now. It is empty.
SELECT * FROM EMPLOYEE;


-- Shows the columns of the table
DESC TABLE EMPLOYEE;


-- ============================================================
-- 5. CREATE FILE FORMAT
-- This tells Snowflake how to read the CSV
-- ============================================================

CREATE FILE FORMAT EMPLOYEE_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'YYYY-MM-DD';


-- Shows the rules you just saved
DESC FILE FORMAT EMPLOYEE_CSV_FORMAT;


-- ============================================================
-- 6. CREATE INTERNAL STAGE
-- This makes a landing spot for the file
-- ============================================================

CREATE STAGE EMPLOYEE_STAGE
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;


-- Shows the stages you have
SHOW STAGES;


-- ============================================================
-- 7. UPLOAD THE CSV AND LIST THE STAGE
-- You upload the file by hand in Snowsight. There is no SQL for that.
-- ============================================================

-- Shows the file now sitting in the stage
LIST @EMPLOYEE_STAGE;


-- ============================================================
-- 8. LOAD THE CSV INTO THE TABLE
-- Moves the file's data from the stage into the EMPLOYEE table
-- ============================================================

COPY INTO EMPLOYEE
FROM @EMPLOYEE_STAGE
FILE_FORMAT = (FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT');


-- ============================================================
-- 9. VERIFY THE LOAD
-- Shows the rows and the number of rows
-- ============================================================

SELECT * FROM EMPLOYEE;


SELECT COUNT(*) FROM EMPLOYEE;


-- ============================================================
-- 10. CHECK THE STAGE STILL HOLDS THE FILE
-- COPY INTO never deletes the file, so it is still there
-- ============================================================

LIST @EMPLOYEE_STAGE;


-- ============================================================
-- 11. CHECK THE LOAD HISTORY
-- Shows the load records for this table in the last day
-- ============================================================

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'SNOWFLAKE_PRACTICE.EMPLOYEE_SCHEMA.EMPLOYEE',
        START_TIME => DATEADD(DAY, -1, CURRENT_TIMESTAMP())
    )
);
