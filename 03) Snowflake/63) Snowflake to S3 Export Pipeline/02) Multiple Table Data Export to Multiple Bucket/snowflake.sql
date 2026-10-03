-- ============================================================
-- 1. CREATE DATABASE
-- Makes a database just for this multi-table / multi-bucket project
-- ============================================================

CREATE DATABASE SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE;


-- Uses this database from now on
USE DATABASE SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Makes a schema (a folder) to keep the project objects together
-- ============================================================

CREATE SCHEMA S3_MULTI_EXPORT_SCHEMA;


-- Uses this schema from now on
USE SCHEMA S3_MULTI_EXPORT_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Makes a small XSMALL machine to run the SQL
-- ============================================================

CREATE WAREHOUSE S3_MULTI_EXPORT_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60       -- Stops after 60 seconds with no work
    AUTO_RESUME = TRUE;     -- Starts again by itself when a query runs


-- Runs the queries on this warehouse
USE WAREHOUSE S3_MULTI_EXPORT_WH;


-- ============================================================
-- 4. CREATE SOURCE TABLES
-- TWO tables, because each table goes to its OWN bucket
--     STUDENT_DATA  ->  student bucket
--     COLLEGE_DATA  ->  college bucket
-- ============================================================

CREATE TABLE STUDENT_DATA (
    STUDENT_ID NUMBER,
    STUDENT_NAME VARCHAR(100),
    COURSE VARCHAR(100),
    CITY VARCHAR(100),
    MARKS NUMBER
);


CREATE TABLE COLLEGE_DATA (
    COLLEGE_ID NUMBER,
    COLLEGE_NAME VARCHAR(100),
    CITY VARCHAR(100),
    UNIVERSITY VARCHAR(100),
    TOTAL_STUDENTS NUMBER
);


SELECT * FROM STUDENT_DATA;
SELECT * FROM COLLEGE_DATA;


-- Shows the columns of both tables
DESC TABLE STUDENT_DATA;
DESC TABLE COLLEGE_DATA;


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- Puts sample rows into both tables
-- ============================================================

INSERT INTO STUDENT_DATA
    (STUDENT_ID, STUDENT_NAME, COURSE, CITY, MARKS)
VALUES
    (301, 'Kshitij', 'Data Engineering', 'Pune', 88),
    (302, 'Rahul', 'AWS Engineering', 'Mumbai', 81),
    (303, 'Amit', 'Data Analytics', 'Bangalore', 76),
    (304, 'Sneha', 'Data Engineering', 'Pune', 91),
    (305, 'Priya', 'Cloud Engineering', 'Hyderabad', 85);


INSERT INTO COLLEGE_DATA
    (COLLEGE_ID, COLLEGE_NAME, CITY, UNIVERSITY, TOTAL_STUDENTS)
VALUES
    (101, 'Fergusson College', 'Pune', 'Savitribai Phule Pune University', 12000),
    (102, 'St. Xaviers College', 'Mumbai', 'University of Mumbai', 9800),
    (103, 'Christ College', 'Bangalore', 'Bangalore University', 14500),
    (104, 'Loyola College', 'Chennai', 'University of Madras', 11000),
    (105, 'Osmania College', 'Hyderabad', 'Osmania University', 8700);


-- Checks the rows you just added
SELECT *
FROM STUDENT_DATA;


SELECT *
FROM COLLEGE_DATA;


-- ============================================================
-- 6. CREATE CSV FILE FORMAT
-- ONE shared format, used by BOTH stages
-- Says what the exported CSV files should look like
-- ============================================================

CREATE FILE FORMAT MULTI_EXPORT_CSV_FORMAT
    TYPE = 'CSV'                        -- Saves the data as CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'  -- Puts double quotes around fields when needed
    SKIP_HEADER = 1                     -- Skips the header row when reading the file back
    COMPRESSION = 'NONE';               -- Keeps the file uncompressed


-- Shows the file formats that exist
SHOW FILE FORMATS;


-- ============================================================
-- 7. CREATE STORAGE INTEGRATION
-- ONE integration for BOTH buckets, so no keys are needed
--
-- BEFORE YOU START:
-- The AWS role SnowflakeS3MultiExportSnowflakeRole must already exist.
-- Put its ARN into STORAGE_AWS_ROLE_ARN below.
--
-- No AWS access keys are stored in Snowflake. Snowflake borrows
-- the role through this integration instead.
--
-- STORAGE_ALLOWED_LOCATIONS lists BOTH bucket paths. One integration
-- is enough for the two buckets.
-- ============================================================

CREATE OR REPLACE STORAGE INTEGRATION S3_MULTI_EXPORT_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN =
        'arn:aws:iam::772346609795:role/SnowflakeS3MultiExportSnowflakeRole'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://snowflake-student-export-2026/student-export/',
        's3://snowflake-college-export-2026/college-export/'
    );


-- ============================================================
-- 8. DESCRIBE STORAGE INTEGRATION
-- Shows the AWS IAM user and the external ID that Snowflake made
--
-- Copy STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID from
-- the output and put them into the trust policy of the AWS role
-- SnowflakeS3MultiExportSnowflakeRole.
-- ============================================================

DESC INTEGRATION S3_MULTI_EXPORT_INTEGRATION;


-- ============================================================
-- 9. CREATE EXTERNAL STAGES
-- TWO stages, because there are TWO buckets.
-- Both stages use the SAME storage integration.
--
--     STUDENT_S3_EXPORT_STAGE  ->  s3://snowflake-student-export-2026/student-export/
--     COLLEGE_S3_EXPORT_STAGE  ->  s3://snowflake-college-export-2026/college-export/
-- ============================================================

CREATE OR REPLACE STAGE STUDENT_S3_EXPORT_STAGE
    URL = 's3://snowflake-student-export-2026/student-export/'
    STORAGE_INTEGRATION = S3_MULTI_EXPORT_INTEGRATION
    FILE_FORMAT = MULTI_EXPORT_CSV_FORMAT;


CREATE OR REPLACE STAGE COLLEGE_S3_EXPORT_STAGE
    URL = 's3://snowflake-college-export-2026/college-export/'
    STORAGE_INTEGRATION = S3_MULTI_EXPORT_INTEGRATION
    FILE_FORMAT = MULTI_EXPORT_CSV_FORMAT;


-- Shows the stages that exist
SHOW STAGES;


-- Shows the settings of the stages we made
DESC STAGE STUDENT_S3_EXPORT_STAGE;
DESC STAGE COLLEGE_S3_EXPORT_STAGE;


-- ============================================================
-- 10. TEST S3 CONNECTIVITY
-- Lists the files that are in each S3 bucket folder right now
--
-- "0 rows" is fine when no file has been exported yet.
-- What matters is that you do NOT get "Access Denied" on
-- either bucket.
-- ============================================================

LIST @STUDENT_S3_EXPORT_STAGE;

LIST @COLLEGE_S3_EXPORT_STAGE;


-- ============================================================
-- 11. CREATE STORED PROCEDURE
-- ONE procedure that exports BOTH tables:
--   STUDENT_DATA -> student bucket as student_data.csv
--   COLLEGE_DATA -> college bucket as college_data.csv
-- AWS Lambda will call this procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE EXPORT_STUDENT_AND_COLLEGE_TO_S3()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN

    -- 1) Writes STUDENT_DATA to ONE file called student_data.csv
    --    in the student bucket
    COPY INTO @STUDENT_S3_EXPORT_STAGE/student_data.csv
    FROM STUDENT_DATA
    FILE_FORMAT = (
        FORMAT_NAME = 'MULTI_EXPORT_CSV_FORMAT'
    )
    HEADER = TRUE       -- Writes the column names as the first row
    SINGLE = TRUE       -- Makes ONE file, not many part files
    OVERWRITE = TRUE;   -- Replaces the file if it is already there

    -- 2) Writes COLLEGE_DATA to ONE file called college_data.csv
    --    in the college bucket
    COPY INTO @COLLEGE_S3_EXPORT_STAGE/college_data.csv
    FROM COLLEGE_DATA
    FILE_FORMAT = (
        FORMAT_NAME = 'MULTI_EXPORT_CSV_FORMAT'
    )
    HEADER = TRUE
    SINGLE = TRUE
    OVERWRITE = TRUE;

    -- Sends a success message back to Lambda
    RETURN 'SUCCESS: STUDENT_DATA exported as student_data.csv and COLLEGE_DATA exported as college_data.csv';

END;
$$;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND
-- Who runs it : AWS Lambda — function snowflake-s3-multi-export-lambda
-- Why         : Lambda is the part that should start the export.
--               This procedure writes student_data.csv and
--               college_data.csv to their buckets. If you run the
--               CALL yourself, the files are exported outside the pipeline.
--               Later, when you press Test in Lambda, you cannot tell
--               whether Lambda really did the work.
-- ============================================================

-- CALL EXPORT_STUDENT_AND_COLLEGE_TO_S3();   <-- left commented out on purpose
-- Lambda runs it with: cursor.execute("CALL EXPORT_STUDENT_AND_COLLEGE_TO_S3()")
