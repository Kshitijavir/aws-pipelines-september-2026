```sql
-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

CREATE OR REPLACE DATABASE LAMBDA_SNOWFLAKE_PRACTICE;

USE DATABASE LAMBDA_SNOWFLAKE_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- ============================================================

CREATE OR REPLACE SCHEMA LAMBDA_SCHEMA;

USE SCHEMA LAMBDA_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- ============================================================

CREATE OR REPLACE WAREHOUSE LAMBDA_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE LAMBDA_WH;


-- ============================================================
-- 4. CREATE STUDENT TABLE
-- ============================================================

CREATE OR REPLACE TABLE STUDENT (
    STUDENT_ID NUMBER,
    STUDENT_NAME VARCHAR(100),
    AGE NUMBER,
    COURSE VARCHAR(100),
    CITY VARCHAR(100)
);

SELECT * FROM STUDENT;


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- ============================================================

INSERT INTO STUDENT
    (STUDENT_ID, STUDENT_NAME, AGE, COURSE, CITY)
VALUES
    (101, 'Kshitij', 30, 'Data Engineering', 'Pune'),
    (102, 'Rahul', 25, 'AWS', 'Mumbai'),
    (103, 'Amit', 27, 'Data Analytics', 'Bangalore'),
    (104, 'Sneha', 24, 'Python', 'Hyderabad'),
    (105, 'Priya', 26, 'Snowflake', 'Chennai');


-- ============================================================
-- 6. VERIFY DATA
-- ============================================================

SELECT *
FROM STUDENT;


-- ============================================================
-- 7. CHECK RECORD COUNT
-- ============================================================

SELECT COUNT(*) AS STUDENT_COUNT
FROM STUDENT;


-- ============================================================
-- 8. CHECK CURRENT CONNECTION DETAILS
-- Run this separately if required
-- ============================================================

SELECT
    CURRENT_USER()       AS USER_NAME,
    CURRENT_ACCOUNT()    AS ACCOUNT,
    CURRENT_WAREHOUSE()  AS WAREHOUSE,
    CURRENT_DATABASE()   AS DATABASE_NAME,
    CURRENT_SCHEMA()     AS SCHEMA_NAME;


-- ============================================================
-- 9. CHECK ORGANIZATION AND ACCOUNT DETAILS
-- ============================================================

SELECT
    CURRENT_ORGANIZATION_NAME() AS ORGANIZATION_NAME,
    CURRENT_ACCOUNT_NAME()      AS ACCOUNT_NAME,
    CURRENT_ACCOUNT()            AS ACCOUNT_LOCATOR,
    CURRENT_REGION()             AS REGION;


-- ============================================================
-- 10. CHECK CURRENT USER
-- ============================================================

SELECT CURRENT_USER();


-- ============================================================
-- 11. UPDATE USER PASSWORD
-- ============================================================

ALTER USER JAVIR
SET PASSWORD = 'Kshitijjavir@42';
```
