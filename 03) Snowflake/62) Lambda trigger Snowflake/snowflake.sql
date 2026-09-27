-- ============================================================
-- 1. CREATE DATABASE
-- Makes a database for this Lambda and Snowflake project
-- ============================================================

CREATE DATABASE LAMBDA_SP_EXPORT_PRACTICE;


-- Uses this database for all the steps below
USE DATABASE LAMBDA_SP_EXPORT_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Makes a schema to hold all the objects of this project
-- ============================================================

CREATE SCHEMA LAMBDA_EXPORT_SCHEMA;


-- Uses this schema for all the steps below
USE SCHEMA LAMBDA_EXPORT_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Makes an XSMALL warehouse to run the queries
-- ============================================================

CREATE WAREHOUSE LAMBDA_EXPORT_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60       -- Stops the warehouse after 60 seconds of no use
    AUTO_RESUME = TRUE;     -- Starts it again when a query runs


-- Uses this warehouse to run the queries
USE WAREHOUSE LAMBDA_EXPORT_WH;


-- ============================================================
-- 4. CREATE SOURCE TABLE
-- Makes the table that holds the employee data
-- ============================================================

CREATE TABLE EMPLOYEE_DATA (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(100),
    CITY VARCHAR(100),
    SALARY NUMBER
);


-- Shows the columns of the table
SELECT * FROM EMPLOYEE_DATA;


-- Shows the structure of the table (column names and types)
DESC TABLE EMPLOYEE_DATA;


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- Adds the sample employee rows to the table
-- ============================================================

INSERT INTO EMPLOYEE_DATA
    (EMPLOYEE_ID, EMPLOYEE_NAME, DEPARTMENT, CITY, SALARY)
VALUES
    (101, 'Kshitij', 'Data Engineering', 'Pune', 1200000),
    (102, 'Rahul', 'AWS Engineering', 'Mumbai', 1000000),
    (103, 'Amit', 'Data Analytics', 'Bangalore', 900000),
    (104, 'Sneha', 'Data Engineering', 'Pune', 1100000),
    (105, 'Priya', 'Cloud Engineering', 'Hyderabad', 1050000);


-- Shows the rows that were added (now 5 rows)
SELECT *
FROM EMPLOYEE_DATA;


-- ============================================================
-- 6. CREATE CSV FILE FORMAT
-- Tells Snowflake how the exported CSV file should look
-- ============================================================

CREATE FILE FORMAT EMPLOYEE_CSV_FORMAT
    TYPE = 'CSV'                       -- Makes the file a CSV file
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' -- Puts double quotes around a value when needed
    SKIP_HEADER = 1                    -- Skips the header line when the file is read
    COMPRESSION = 'NONE';              -- Keeps the file uncompressed


-- Shows all the file formats
SHOW FILE FORMATS;


-- ============================================================
-- 7. CREATE INTERNAL STAGE
-- Makes a stage to keep the exported CSV files
-- ============================================================

CREATE STAGE EMPLOYEE_EXPORT_STAGE
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;


-- Shows all the stages
SHOW STAGES;


-- Shows the details of this stage
DESC STAGE EMPLOYEE_EXPORT_STAGE;


-- ============================================================
-- 8. CREATE STORED PROCEDURE
-- Makes the procedure that writes the employee data into the stage
-- AWS Lambda calls this procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE EXPORT_EMPLOYEE_DATA()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN

    -- This writes the data into the stage as CSV
    COPY INTO @EMPLOYEE_EXPORT_STAGE
    FROM EMPLOYEE_DATA
    FILE_FORMAT = (FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT')
    OVERWRITE = TRUE;

    -- Sends a success message back to Lambda
    RETURN 'Employee data successfully exported to Snowflake stage';

END;
$$;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND
-- Who runs it : AWS Lambda
-- Why         : Lambda is the only thing that should start this
--               export. If you run the CALL yourself, the export
--               runs outside the pipeline, and later you cannot
--               tell whether Lambda really did the work.
-- ============================================================

-- CALL EXPORT_EMPLOYEE_DATA();      <-- left commented out on purpose
-- Lambda runs it with: cursor.execute("CALL EXPORT_EMPLOYEE_DATA()")