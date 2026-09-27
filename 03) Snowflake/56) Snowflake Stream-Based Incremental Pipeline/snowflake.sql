-- ============================================================
-- 56) Snowflake — Stream-Based Incremental Pipeline
-- All the SQL for this pipeline, in README order.
-- Paste this whole file into a Snowflake worksheet and run it
-- from top to bottom.
--
-- A stream is a change tracker. It holds only the rows that
-- changed in a table. So you do not read the whole table again.
-- This pipeline copies those changed rows into a target table.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE   (README Step 1)
-- Makes the big box that holds everything below.
-- ============================================================

CREATE DATABASE SNOWFLAKE_STREAM_PRACTICE;

-- Picks the database for the rest of the file.
USE DATABASE SNOWFLAKE_STREAM_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA   (README Step 2)
-- Makes a folder inside the database to keep the objects together.
-- ============================================================

CREATE SCHEMA STREAM_SCHEMA;

-- Picks the schema for the rest of the file.
USE SCHEMA STREAM_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE   (README Step 3)
-- Makes the machine that runs the SQL.
-- ============================================================

CREATE WAREHOUSE STREAM_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Picks the warehouse used to run the queries.
USE WAREHOUSE STREAM_WH;


-- ============================================================
-- 4. CREATE THE SOURCE TABLE   (README Step 4)
-- Makes the table that the stream will watch.
-- ============================================================

CREATE TABLE EMPLOYEE_SOURCE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);

SELECT * FROM EMPLOYEE_SOURCE;


-- ============================================================
-- 5. INSERT INITIAL DATA   (README Step 5)
-- Adds 3 employees. The stream is not made yet, so these rows
-- are not seen as changes.
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(7001, 'Rahul Sharma', 'IT', 85000),
(7002, 'Priya Patil', 'HR', 62000),
(7003, 'Amit Verma', 'Finance', 95000);

-- Shows the 3 rows in the source table.
SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 6. CREATE THE STREAM   (README Step 6)
-- Starts watching the source table for changes from now on.
-- ============================================================

CREATE STREAM EMPLOYEE_STREAM
ON TABLE EMPLOYEE_SOURCE;

-- Shows the streams.
SHOW STREAMS;


-- ============================================================
-- 7. INSERT A NEW EMPLOYEE   (README Step 7)
-- Adds a 4th employee. The stream notes this row as a change.
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(7004, 'Sneha Joshi', 'IT', 78000);

-- Shows the source table. It now has 4 employees.
SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;


-- ============================================================
-- 8. READ THE STREAM   (README Step 8)
-- Shows the changed row. A plain SELECT does not empty the stream.
-- ============================================================

SELECT * FROM EMPLOYEE_STREAM;


-- ============================================================
-- 9. UPDATE AN EXISTING EMPLOYEE   (README Step 9)
-- Changes one salary. The stream notes this change.
-- ============================================================

UPDATE EMPLOYEE_SOURCE
SET SALARY = 90000
WHERE EMPLOYEE_ID = 7001;

-- Reads the stream again. The update shows up here.
SELECT * FROM EMPLOYEE_STREAM;


-- ============================================================
-- 10. DELETE AN EMPLOYEE   (README Step 10)
-- Removes one employee. The stream notes this delete.
-- ============================================================

DELETE FROM EMPLOYEE_SOURCE
WHERE EMPLOYEE_ID = 7003;

-- Reads the stream again. The delete shows up here.
SELECT * FROM EMPLOYEE_STREAM;


-- ============================================================
-- 11. CREATE THE TARGET TABLE   (README Step 11)
-- Makes the table that will get the changed rows.
-- ============================================================

CREATE TABLE EMPLOYEE_TARGET (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);

SELECT * FROM EMPLOYEE_TARGET;


-- ============================================================
-- 12. CONSUME THE STREAM   (README Step 12)
-- Copies the changed rows out of the stream into the target table.
-- ⚠️ This INSERT uses up the stream. Run it only ONCE for this
-- set of changes. See the DO NOT RUN block at the end of this file.
-- ============================================================

INSERT INTO EMPLOYEE_TARGET
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    DEPARTMENT,
    SALARY
FROM EMPLOYEE_STREAM;

-- Shows the target table. The changed rows are here now.
SELECT * FROM EMPLOYEE_TARGET;


-- ============================================================
-- 13. CREATE A SECOND TARGET TABLE   (README Step 13)
-- Makes EMPLOYEE_FINAL. This table is used for the better
-- Stream -> MERGE -> Target pattern.
-- ============================================================

CREATE TABLE EMPLOYEE_FINAL (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);

SELECT * FROM EMPLOYEE_FINAL;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND OR AGAIN
-- Who runs it : You - one time only, as Step 12 above.
--               Nothing else runs it. This practice pipeline
--               has no Lambda and no Snowflake task.
-- Why         : Reading a stream inside a DML statement (INSERT,
--               UPDATE, DELETE, MERGE) uses up the stream rows.
--               Run this INSERT a second time and it copies 0 rows,
--               because the changes are already gone.
-- ============================================================

-- INSERT INTO EMPLOYEE_TARGET
-- SELECT
--     EMPLOYEE_ID,
--     EMPLOYEE_NAME,
--     DEPARTMENT,
--     SALARY
-- FROM EMPLOYEE_STREAM;
