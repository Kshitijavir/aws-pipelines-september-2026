-- ============================================================
-- 52) Snowflake - Table-to-Stage Export Pipeline
-- Folder 02 - Multiple Table export to Multiple Stage
-- All the SQL for this pipeline, in README order.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- This pipeline sends data OUT of Snowflake. The command that does it
-- is COPY INTO @stage, and you are meant to run it yourself.
-- 4 tables go into 4 stages, so you run 4 export commands.
-- 5 rows per table = 20 rows in total.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- This makes a database for this practice
-- ============================================================

CREATE DATABASE CUSTOMER_EXPORT_DB;

-- Use this database from now on
USE DATABASE CUSTOMER_EXPORT_DB;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- This makes a folder inside the database
-- ============================================================

CREATE SCHEMA CUSTOMER_EXPORT_SCHEMA;

-- Use this schema from now on
USE SCHEMA CUSTOMER_EXPORT_SCHEMA;


-- ============================================================
-- STEP 3. CREATE WAREHOUSE
-- This makes a small machine that runs the SQL
-- ============================================================

CREATE WAREHOUSE CUSTOMER_EXPORT_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Use this machine to run the SQL
USE WAREHOUSE CUSTOMER_EXPORT_WH;


-- ============================================================
-- STEP 4. CREATE AND FILL CUSTOMER TABLE 1
-- This is the first source table. It holds 5 rows
-- ============================================================

CREATE TABLE CUSTOMER_DATA_1 (
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  VARCHAR(100),
    EMAIL          VARCHAR(200),
    CITY           VARCHAR(100),
    COUNTRY        VARCHAR(50),
    TOTAL_PURCHASE NUMBER
);

-- Adds 5 rows to the table
INSERT INTO CUSTOMER_DATA_1 VALUES
(3001, 'Rahul Sharma', 'rahul@example.com', 'Mumbai', 'India', 75000),
(3002, 'Priya Patil', 'priya@example.com', 'Pune', 'India', 62000),
(3003, 'Amit Verma', 'amit@example.com', 'Delhi', 'India', 58000),
(3004, 'Sneha Joshi', 'sneha@example.com', 'Bengaluru', 'India', 91000),
(3005, 'Vikas Kumar', 'vikas@example.com', 'Hyderabad', 'India', 67000);

-- Shows the 5 rows
SELECT * FROM CUSTOMER_DATA_1;


-- ============================================================
-- STEP 5. CREATE AND FILL CUSTOMER TABLE 2
-- The same columns as table 1, but its own rows
-- ============================================================

CREATE TABLE CUSTOMER_DATA_2 (
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  VARCHAR(100),
    EMAIL          VARCHAR(200),
    CITY           VARCHAR(100),
    COUNTRY        VARCHAR(50),
    TOTAL_PURCHASE NUMBER
);

-- Adds 5 rows to the table
INSERT INTO CUSTOMER_DATA_2 VALUES
(4001, 'Arjun Mehta', 'arjun@example.com', 'Chennai', 'India', 82000),
(4002, 'Neha Singh', 'neha@example.com', 'Kolkata', 'India', 71000),
(4003, 'Rohit Gupta', 'rohit@example.com', 'Noida', 'India', 65000),
(4004, 'Pooja Shah', 'pooja@example.com', 'Ahmedabad', 'India', 89000),
(4005, 'Karan Rao', 'karan@example.com', 'Bengaluru', 'India', 76000);

-- Shows the 5 rows
SELECT * FROM CUSTOMER_DATA_2;


-- ============================================================
-- STEP 6. CREATE AND FILL CUSTOMER TABLE 3
-- The same columns as table 1, but its own rows
-- ============================================================

CREATE TABLE CUSTOMER_DATA_3 (
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  VARCHAR(100),
    EMAIL          VARCHAR(200),
    CITY           VARCHAR(100),
    COUNTRY        VARCHAR(50),
    TOTAL_PURCHASE NUMBER
);

-- Adds 5 rows to the table
INSERT INTO CUSTOMER_DATA_3 VALUES
(5001, 'Sanjay Kumar', 'sanjay@example.com', 'Jaipur', 'India', 55000),
(5002, 'Anjali Nair', 'anjali@example.com', 'Kochi', 'India', 68000),
(5003, 'Manish Yadav', 'manish@example.com', 'Lucknow', 'India', 72000),
(5004, 'Divya Iyer', 'divya@example.com', 'Coimbatore', 'India', 93000),
(5005, 'Nikhil Jain', 'nikhil@example.com', 'Indore', 'India', 61000);

-- Shows the 5 rows
SELECT * FROM CUSTOMER_DATA_3;


-- ============================================================
-- STEP 7. CREATE AND FILL CUSTOMER TABLE 4
-- The same columns as table 1, but its own rows
-- ============================================================

CREATE TABLE CUSTOMER_DATA_4 (
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  VARCHAR(100),
    EMAIL          VARCHAR(200),
    CITY           VARCHAR(100),
    COUNTRY        VARCHAR(50),
    TOTAL_PURCHASE NUMBER
);

-- Adds 5 rows to the table
INSERT INTO CUSTOMER_DATA_4 VALUES
(6001, 'Varun Kapoor', 'varun@example.com', 'Gurugram', 'India', 88000),
(6002, 'Meera Reddy', 'meera@example.com', 'Hyderabad', 'India', 79000),
(6003, 'Akash Malhotra', 'akash@example.com', 'Mumbai', 'India', 69000),
(6004, 'Riya Desai', 'riya@example.com', 'Pune', 'India', 97000),
(6005, 'Suresh Babu', 'suresh@example.com', 'Chennai', 'India', 73000);

-- Shows the 5 rows
SELECT * FROM CUSTOMER_DATA_4;


-- ============================================================
-- STEP 8. CREATE THE EXPORT FILE FORMAT
-- This tells Snowflake how to write the CSV files.
-- One format is enough for all four stages
-- ============================================================

CREATE FILE FORMAT CUSTOMER_CSV_EXPORT_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';


-- ============================================================
-- STEP 9. CREATE THE FOUR EXPORT STAGES
-- Each stage receives the file of one table
-- ============================================================

CREATE STAGE CUSTOMER_EXPORT_STAGE_1
    FILE_FORMAT = CUSTOMER_CSV_EXPORT_FORMAT;


CREATE STAGE CUSTOMER_EXPORT_STAGE_2
    FILE_FORMAT = CUSTOMER_CSV_EXPORT_FORMAT;


CREATE STAGE CUSTOMER_EXPORT_STAGE_3
    FILE_FORMAT = CUSTOMER_CSV_EXPORT_FORMAT;


CREATE STAGE CUSTOMER_EXPORT_STAGE_4
    FILE_FORMAT = CUSTOMER_CSV_EXPORT_FORMAT;

-- Shows the stages you have
SHOW STAGES;


-- ============================================================
-- STEP 10. CHECK THE STAGES BEFORE THE EXPORT
-- All four stages are empty at this point.
-- Compare this with Step 12, after the export
-- ============================================================

LIST @CUSTOMER_EXPORT_STAGE_1;

LIST @CUSTOMER_EXPORT_STAGE_2;

LIST @CUSTOMER_EXPORT_STAGE_3;

LIST @CUSTOMER_EXPORT_STAGE_4;


-- ============================================================
-- STEP 11. EXPORT EACH TABLE INTO ITS OWN STAGE
-- Four commands. Only the table name and the stage name
-- change from one command to the next.
-- HEADER = TRUE puts the column names in the first line of the file
-- ============================================================

COPY INTO @CUSTOMER_EXPORT_STAGE_1
FROM CUSTOMER_DATA_1
HEADER = TRUE;


COPY INTO @CUSTOMER_EXPORT_STAGE_2
FROM CUSTOMER_DATA_2
HEADER = TRUE;


COPY INTO @CUSTOMER_EXPORT_STAGE_3
FROM CUSTOMER_DATA_3
HEADER = TRUE;


COPY INTO @CUSTOMER_EXPORT_STAGE_4
FROM CUSTOMER_DATA_4
HEADER = TRUE;


-- ============================================================
-- STEP 12. CHECK THE EXPORTED FILES
-- Every stage now holds one file called data_0_0_0.csv
-- ============================================================

LIST @CUSTOMER_EXPORT_STAGE_1;

LIST @CUSTOMER_EXPORT_STAGE_2;

LIST @CUSTOMER_EXPORT_STAGE_3;

LIST @CUSTOMER_EXPORT_STAGE_4;
