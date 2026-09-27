-- ============================================================
-- 1. CREATE DATABASE
-- Makes a database just for this S3 export project
-- ============================================================

CREATE DATABASE SNOWFLAKE_S3_EXPORT_PRACTICE;


-- Uses this database from now on
USE DATABASE SNOWFLAKE_S3_EXPORT_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Makes a schema (a folder) to keep the project objects together
-- ============================================================

CREATE SCHEMA S3_EXPORT_SCHEMA;


-- Uses this schema from now on
USE SCHEMA S3_EXPORT_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Makes a small XSMALL machine to run the SQL
-- ============================================================

CREATE WAREHOUSE S3_EXPORT_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60       -- Stops after 60 seconds with no work
    AUTO_RESUME = TRUE;     -- Starts again by itself when a query runs


-- Runs the queries on this warehouse
USE WAREHOUSE S3_EXPORT_WH;


-- ============================================================
-- 4. CREATE SOURCE TABLE
-- Makes the table that holds the staff data we want to export
-- ============================================================

CREATE TABLE STAFF_DATA (
    STAFF_ID NUMBER,
    STAFF_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(100),
    CITY VARCHAR(100),
    SALARY NUMBER
);

SELECT * FROM STAFF_DATA;


-- Shows the columns of the table
DESC TABLE STAFF_DATA;


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- Puts sample staff rows into the table
-- ============================================================

INSERT INTO STAFF_DATA
    (STAFF_ID, STAFF_NAME, DEPARTMENT, CITY, SALARY)
VALUES
    (201, 'Kshitij', 'Data Engineering', 'Pune', 1200000),
    (202, 'Rahul', 'AWS Engineering', 'Mumbai', 1000000),
    (203, 'Amit', 'Data Analytics', 'Bangalore', 900000),
    (204, 'Sneha', 'Data Engineering', 'Pune', 1100000),
    (205, 'Priya', 'Cloud Engineering', 'Hyderabad', 1050000);


-- Checks the rows you just added
SELECT *
FROM STAFF_DATA;


-- ============================================================
-- 6. CREATE CSV FILE FORMAT
-- Says what the exported CSV file should look like
-- ============================================================

CREATE FILE FORMAT STAFF_CSV_FORMAT
    TYPE = 'CSV'                        -- Saves the data as CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'  -- Puts double quotes around fields when needed
    SKIP_HEADER = 1                     -- Skips the header row when reading the file back
    COMPRESSION = 'NONE';               -- Keeps the file uncompressed


-- Shows the file formats that exist
SHOW FILE FORMATS;


-- ============================================================
-- 7. CREATE STORAGE INTEGRATION
-- This connects Snowflake to Amazon S3, so no keys are needed
--
-- BEFORE YOU START:
-- The AWS role SnowflakeS3ExportSnowflakeRole must already exist.
-- Put its ARN into STORAGE_AWS_ROLE_ARN below.
--
-- No AWS access keys are stored in Snowflake. Snowflake borrows
-- the role through this integration instead.
-- ============================================================

CREATE OR REPLACE STORAGE INTEGRATION S3_EXPORT_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN =
        'arn:aws:iam::772346609795:role/SnowflakeS3ExportSnowflakeRole'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://snowflake-s3-export-practice-2026/employee-export/'
    );


-- ============================================================
-- 8. DESCRIBE STORAGE INTEGRATION
-- Shows the AWS IAM user and the external ID that Snowflake made
--
-- Copy STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID from
-- the output and put them into the trust policy of the AWS role
-- SnowflakeS3ExportSnowflakeRole.
-- ============================================================

DESC INTEGRATION S3_EXPORT_INTEGRATION;


-- ============================================================
-- 9. CREATE EXTERNAL STAGE
-- Makes a stage that points at the S3 folder
-- ============================================================

CREATE OR REPLACE STAGE STAFF_S3_EXPORT_STAGE
    URL = 's3://snowflake-s3-export-practice-2026/employee-export/'
    STORAGE_INTEGRATION = S3_EXPORT_INTEGRATION
    FILE_FORMAT = STAFF_CSV_FORMAT;


-- Shows the stages that exist
SHOW STAGES;


-- Shows the settings of the stage we made
DESC STAGE STAFF_S3_EXPORT_STAGE;


-- ============================================================
-- 10. TEST S3 CONNECTIVITY
-- Lists the files that are in the S3 folder right now
--
-- "0 rows" is fine when no file has been exported yet.
-- What matters is that you do NOT get "Access Denied".
-- ============================================================

LIST @STAFF_S3_EXPORT_STAGE;


-- ============================================================
-- 11. CREATE STORED PROCEDURE
-- Sends STAFF_DATA to S3 as ONE CSV file with a fixed name
-- AWS Lambda will call this procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE EXPORT_STAFF_TO_S3()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN

    -- Writes STAFF_DATA to ONE file called staff_data.csv in S3
    COPY INTO @STAFF_S3_EXPORT_STAGE/staff_data.csv
    FROM STAFF_DATA
    FILE_FORMAT = (
        FORMAT_NAME = 'STAFF_CSV_FORMAT'
    )
    HEADER = TRUE       -- Writes the column names as the first row
    SINGLE = TRUE       -- Makes ONE file, not many part files
    OVERWRITE = TRUE;   -- Replaces the file if it is already there

    -- Sends a success message back to Lambda
    RETURN 'SUCCESS: Staff data successfully exported to S3 as staff_data.csv';

END;
$$;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND
-- Who runs it : AWS Lambda — function snowflake-s3-export-lambda
-- Why         : Lambda is the part that should start the export.
--               This procedure writes staff_data.csv to S3. If you run the
--               CALL yourself, the file is exported outside the pipeline.
--               Later, when you press Test in Lambda, you cannot tell
--               whether Lambda really did the work.
-- ============================================================

-- CALL EXPORT_STAFF_TO_S3();      <-- left commented out on purpose
-- Lambda runs it with: cursor.execute("CALL EXPORT_STAFF_TO_S3()")
