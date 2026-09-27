-- ============================================================
-- 56) Snowflake — Stream-Based Incremental Pipeline
-- Every SQL statement for this pipeline, in README order.
-- Paste this whole file into a Snowflake worksheet and run it
-- top to bottom.
--
-- A stream is a change tracker. It holds only the rows that
-- changed in a table, so you do not have to read the whole table
-- again. This pipeline copies those changed rows into a target table.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE   (README Step 1)
-- Creates the big box that holds everything below
-- ============================================================

CREATE DATABASE SNOWFLAKE_STREAM_PRACTICE;

-- Selects the database for the remaining operations
USE DATABASE SNOWFLAKE_STREAM_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA   (README Step 2)
-- Creates a folder inside the database to keep the objects together
-- ============================================================

CREATE SCHEMA STREAM_SCHEMA;

-- Selects the schema for the remaining operations
USE SCHEMA STREAM_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE   (README Step 3)
-- Creates the machine that runs the SQL
-- ============================================================

CREATE WAREHOUSE STREAM_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Selects the warehouse used to run the queries
USE WAREHOUSE STREAM_WH;


-- ============================================================
-- 4. CREATE THE SOURCE TABLE   (README Step 4)
-- Creates the table that the stream will watch
-- ============================================================

CREATE TABLE EMPLOYEE_SOURCE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);


-- ============================================================
-- 5. INSERT INITIAL DATA   (README Step 5)
-- Adds 3 employees. The stream does not exist yet, so these rows
-- are not treated as changes
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(7001, 'Rahul Sharma', 'IT', 85000),
(7002, 'Priya Patil', 'HR', 62000),
(7003, 'Amit Verma', 'Finance', 95000);

-- Checks the 3 rows in the source table
SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 6. CREATE THE STREAM   (README Step 6)
-- Starts tracking changes on the source table from this moment on
-- ============================================================

CREATE STREAM EMPLOYEE_STREAM
ON TABLE EMPLOYEE_SOURCE;

-- Shows the streams
SHOW STREAMS;


-- ============================================================
-- 7. INSERT A NEW EMPLOYEE   (README Step 7)
-- Adds a 4th employee. The stream records this row as a change
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(7004, 'Sneha Joshi', 'IT', 78000);

-- Checks the source table - it now holds 4 employees
SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 8. READ THE STREAM   (README Step 8)
-- Shows the changed row. A plain SELECT does not use up the stream
-- ============================================================

SELECT * FROM EMPLOYEE_STREAM;


-- ============================================================
-- 9. UPDATE AN EXISTING EMPLOYEE   (README Step 9)
-- Changes one salary. The stream records the change
-- ============================================================

UPDATE EMPLOYEE_SOURCE
SET SALARY = 90000
WHERE EMPLOYEE_ID = 7001;

-- Reads the stream again - the update shows up as a change
SELECT * FROM EMPLOYEE_STREAM;


-- ============================================================
-- 10. DELETE AN EMPLOYEE   (README Step 10)
-- Removes one employee. The stream records the delete
-- ============================================================

DELETE FROM EMPLOYEE_SOURCE
WHERE EMPLOYEE_ID = 7003;

-- Reads the stream again - the delete shows up as a change
SELECT * FROM EMPLOYEE_STREAM;


-- ============================================================
-- 11. CREATE THE TARGET TABLE   (README Step 11)
-- Creates the table that will receive the changed rows
-- ============================================================

CREATE TABLE EMPLOYEE_TARGET (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);


-- ============================================================
-- 12. CONSUME THE STREAM   (README Step 12)
-- Copies the changed rows out of the stream into the target table.
-- ⚠️ This INSERT uses up the stream. Run it only ONCE for this set
-- of changes - see the DO NOT RUN block at the end of this file
-- ============================================================

INSERT INTO EMPLOYEE_TARGET
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    DEPARTMENT,
    SALARY
FROM EMPLOYEE_STREAM;

-- Checks the target table - the changed rows are now here
SELECT * FROM EMPLOYEE_TARGET;


-- ============================================================
-- 13. CREATE A SECOND TARGET TABLE   (README Step 13)
-- Creates EMPLOYEE_FINAL, the table used for the better
-- Stream -> MERGE -> Target pattern
-- ============================================================

CREATE TABLE EMPLOYEE_FINAL (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND / AGAIN
-- Who runs it : You - once, as Step 12 of this walkthrough.
--               Nothing else runs it (this practice pipeline has
--               no Lambda and no Snowflake task)
-- Why         : Reading a stream inside a DML statement (INSERT,
--               UPDATE, DELETE, MERGE) uses up the stream rows.
--               Run this INSERT a second time and it copies 0 rows,
--               because the changes are already gone
-- ============================================================

-- INSERT INTO EMPLOYEE_TARGET
-- SELECT
--     EMPLOYEE_ID,
--     EMPLOYEE_NAME,
--     DEPARTMENT,
--     SALARY
-- FROM EMPLOYEE_STREAM;
