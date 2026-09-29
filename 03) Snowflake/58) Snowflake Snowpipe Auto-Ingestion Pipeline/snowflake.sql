-- ============================================================
-- 58) Snowflake - Snowpipe Auto-Ingestion Pipeline
-- All the SQL for this pipeline, in the same order as the README.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- The pipe does the loading here. Step 7 makes it, and the COPY INTO
-- inside it is the load rule Snowpipe runs by itself.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- Makes the big box that holds everything below
-- ============================================================

CREATE DATABASE SNOWFLAKE_SNOWPIPE_PRACTICE;


-- Uses this database for all the steps below
USE DATABASE SNOWFLAKE_SNOWPIPE_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Makes a folder inside the database to keep the objects together
-- ============================================================

CREATE SCHEMA SNOWPIPE_SCHEMA;


-- Uses this schema for all the steps below
USE SCHEMA SNOWPIPE_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Makes the machine that runs the SQL for Snowpipe
-- ============================================================

CREATE WAREHOUSE SNOWPIPE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;


-- Uses this machine to run the queries
USE WAREHOUSE SNOWPIPE_WH;


-- ============================================================
-- 4. CREATE TABLE
-- Makes the table that the pipe loads the CSV rows into
-- ============================================================

CREATE TABLE EMPLOYEE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER,
    JOINING_DATE  DATE
);


SELECT * FROM EMPLOYEE;


-- Shows the columns of the table
DESC TABLE EMPLOYEE;


-- ============================================================
-- 5. CREATE FILE FORMAT
-- Tells Snowflake how to read the CSV files
-- ============================================================

CREATE FILE FORMAT EMPLOYEE_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'YYYY-MM-DD';


-- Shows the reading rules written in the file format
DESC FILE FORMAT EMPLOYEE_CSV_FORMAT;


-- ============================================================
-- 6. CREATE INTERNAL STAGE
-- Makes a landing spot inside Snowflake for the CSV files
-- ============================================================

CREATE STAGE EMPLOYEE_STAGE
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;


-- Shows the stages
SHOW STAGES;


-- ============================================================
-- 7. CREATE THE SNOWPIPE
-- Makes the pipe that loads new files by itself
-- The COPY INTO inside it is the load rule Snowpipe runs
-- ============================================================

CREATE PIPE EMPLOYEE_PIPE
AS
COPY INTO EMPLOYEE
FROM @EMPLOYEE_STAGE
FILE_FORMAT = (
    FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT'
);


-- The load rule kept inside the pipe is:
-- COPY INTO EMPLOYEE
-- FROM @EMPLOYEE_STAGE


-- ============================================================
-- 8. CHECK THE PIPE
-- Shows the pipe and the COPY INTO kept inside it
-- ============================================================

SHOW PIPES;


DESC PIPE EMPLOYEE_PIPE;


-- ============================================================
-- 9. CHECK THE PIPE STATUS
-- Shows if the pipe is running or stopped right now
-- ============================================================

SELECT SYSTEM$PIPE_STATUS('EMPLOYEE_PIPE');


-- ============================================================
-- 10. CREATE THE INPUT CSV
-- Nothing to run here - first.csv is made by hand, or taken
-- from the "input files" folder
-- ============================================================


-- ============================================================
-- 11. UPLOAD THE CSV TO THE STAGE
-- Nothing to run here - upload first.csv by hand in Snowsight:
-- Data -> Databases -> SNOWFLAKE_SNOWPIPE_PRACTICE -> SNOWPIPE_SCHEMA
--      -> Stages -> EMPLOYEE_STAGE -> Upload Files
-- ============================================================


-- ============================================================
-- 12. VERIFY THE STAGE
-- Shows the file sitting in the stage now
-- ============================================================

LIST @EMPLOYEE_STAGE;


-- ============================================================
-- 13. TRIGGER A SNOWPIPE REFRESH
-- Tells the pipe to load the new files sitting in the stage
-- ============================================================

ALTER PIPE EMPLOYEE_PIPE REFRESH;


-- ============================================================
-- 14. CHECK THE TABLE
-- Shows the 3 rows the pipe loaded from first.csv, and the row count
-- ============================================================

SELECT * FROM EMPLOYEE ORDER BY EMPLOYEE_ID;


SELECT COUNT(*) FROM EMPLOYEE;


-- ============================================================
-- 15. ADD ANOTHER FILE
-- Nothing to run here - make second.csv by hand and upload it
-- to EMPLOYEE_STAGE in Snowsight, just like first.csv
-- ============================================================


-- ============================================================
-- 16. CHECK THE STAGE AGAIN
-- Shows both files sitting in the stage
-- ============================================================

LIST @EMPLOYEE_STAGE;


-- ============================================================
-- 17. REFRESH SNOWPIPE AGAIN
-- The pipe skips the file it already loaded and loads the new one
-- ============================================================

ALTER PIPE EMPLOYEE_PIPE REFRESH;


-- ============================================================
-- 18. VERIFY AGAIN
-- Shows all 5 rows from both files, and the row count
-- ============================================================

SELECT * FROM EMPLOYEE ORDER BY EMPLOYEE_ID;


SELECT COUNT(*) FROM EMPLOYEE;


-- ============================================================
-- 19. CHECK THE SNOWPIPE STATUS
-- Same check as step 9, so nothing new to run here.
-- ============================================================


-- ============================================================
-- 20. CHECK THE LOAD HISTORY
-- Shows which files loaded, and how many rows each file added
-- ============================================================

SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    LAST_LOAD_TIME
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA.EMPLOYEE',
        START_TIME => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;


-- ============================================================
-- 21. CHECK THE PIPE USAGE HISTORY
-- Shows how much the pipe has been used
-- ============================================================

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(
        DATE_RANGE_START => DATEADD(HOUR, -1, CURRENT_TIMESTAMP()),
        DATE_RANGE_END => CURRENT_TIMESTAMP()
    )
);
