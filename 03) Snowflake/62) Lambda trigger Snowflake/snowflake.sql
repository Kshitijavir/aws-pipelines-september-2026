-- ============================================================
-- 1. CREATE DATABASE
-- Creates a separate database for this Lambda + Snowflake project
-- ============================================================

CREATE DATABASE LAMBDA_SP_EXPORT_PRACTICE;


-- Selects the database for the remaining operations
USE DATABASE LAMBDA_SP_EXPORT_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Creates a schema to organize all project objects
-- ============================================================

CREATE SCHEMA LAMBDA_EXPORT_SCHEMA;


-- Selects the schema for the remaining operations
USE SCHEMA LAMBDA_EXPORT_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Creates an XSMALL compute warehouse for this practice project
-- ============================================================

CREATE WAREHOUSE LAMBDA_EXPORT_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60       -- Suspends after 60 seconds of inactivity
    AUTO_RESUME = TRUE;     -- Automatically resumes when a query runs


-- Selects the warehouse used to execute queries
USE WAREHOUSE LAMBDA_EXPORT_WH;


-- ============================================================
-- 4. CREATE SOURCE TABLE
-- Creates the table containing the employee data to be exported
-- ============================================================

CREATE TABLE EMPLOYEE_DATA (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(100),
    CITY VARCHAR(100),
    SALARY NUMBER
);


-- Displays the table structure and column definitions
DESC TABLE EMPLOYEE_DATA;


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- Inserts sample employee records into the source table
-- ============================================================

INSERT INTO EMPLOYEE_DATA
    (EMPLOYEE_ID, EMPLOYEE_NAME, DEPARTMENT, CITY, SALARY)
VALUES
    (101, 'Kshitij', 'Data Engineering', 'Pune', 1200000),
    (102, 'Rahul', 'AWS Engineering', 'Mumbai', 1000000),
    (103, 'Amit', 'Data Analytics', 'Bangalore', 900000),
    (104, 'Sneha', 'Data Engineering', 'Pune', 1100000),
    (105, 'Priya', 'Cloud Engineering', 'Hyderabad', 1050000);


-- Verifies the employee data inserted into the table
SELECT *
FROM EMPLOYEE_DATA;


-- ============================================================
-- 6. CREATE CSV FILE FORMAT
-- Defines how Snowflake should format the exported CSV files
-- ============================================================

CREATE FILE FORMAT EMPLOYEE_CSV_FORMAT
    TYPE = 'CSV'                       -- Export data in CSV format
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' -- Encloses fields with double quotes when needed
    SKIP_HEADER = 1                    -- Skips the header when reading the file
    COMPRESSION = 'NONE';              -- Does not compress the CSV file


-- Displays the available file formats
SHOW FILE FORMATS;


-- ============================================================
-- 7. CREATE INTERNAL STAGE
-- Creates a Snowflake internal stage to store exported CSV files
-- ============================================================

CREATE STAGE EMPLOYEE_EXPORT_STAGE
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;


-- Displays the available stages
SHOW STAGES;


-- Displays the configuration/details of the created stage
DESC STAGE EMPLOYEE_EXPORT_STAGE;


-- ============================================================
-- 8. CREATE STORED PROCEDURE
-- Creates the procedure that will export employee data to the stage
-- AWS Lambda will call this procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE EXPORT_EMPLOYEE_DATA()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN

    -- Exports EMPLOYEE_DATA into the Snowflake internal stage as CSV
    COPY INTO @EMPLOYEE_EXPORT_STAGE
    FROM EMPLOYEE_DATA
    FILE_FORMAT = (FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT')
    OVERWRITE = TRUE;

    -- Returns a success message to Lambda
    RETURN 'Employee data successfully exported to Snowflake stage';

END;
$$;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND
-- Who runs it : AWS Lambda
-- Why         : Lambda is the only thing that should start this
--               export. If you run the CALL yourself, the export
--               happens outside the pipeline, and when you press
--               Test in Lambda later you can no longer tell
--               whether Lambda really did the work.
-- ============================================================

-- CALL EXPORT_EMPLOYEE_DATA();      <-- left commented out on purpose
-- Lambda runs it with: cursor.execute("CALL EXPORT_EMPLOYEE_DATA()")