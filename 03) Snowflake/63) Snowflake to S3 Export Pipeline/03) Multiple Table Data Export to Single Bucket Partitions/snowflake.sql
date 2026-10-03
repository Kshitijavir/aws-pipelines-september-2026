-- ============================================================
-- 1. CREATE DATABASE
-- Makes a database just for this partition-export project
-- ============================================================

CREATE DATABASE SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE;


-- Uses this database from now on
USE DATABASE SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Makes a schema (a folder) to keep the project objects together
-- ============================================================

CREATE SCHEMA S3_PARTITION_EXPORT_SCHEMA;


-- Uses this schema from now on
USE SCHEMA S3_PARTITION_EXPORT_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Makes a small XSMALL machine to run the SQL
-- ============================================================

CREATE WAREHOUSE S3_PARTITION_EXPORT_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60       -- Stops after 60 seconds with no work
    AUTO_RESUME = TRUE;     -- Starts again by itself when a query runs


-- Runs the queries on this warehouse
USE WAREHOUSE S3_PARTITION_EXPORT_WH;


-- ============================================================
-- 4. CREATE SOURCE TABLES
-- TWO tables, but only ONE bucket.
-- Each table gets its OWN folder (partition) inside that bucket:
--     STUDENT_RECORDS  ->  student/ folder
--     COLLEGE_RECORDS  ->  college/ folder
-- ============================================================

CREATE TABLE STUDENT_RECORDS (
    STUDENT_ID NUMBER,
    STUDENT_NAME VARCHAR(100),
    COURSE VARCHAR(100),
    CITY VARCHAR(100),
    MARKS NUMBER
);


CREATE TABLE COLLEGE_RECORDS (
    COLLEGE_ID NUMBER,
    COLLEGE_NAME VARCHAR(100),
    CITY VARCHAR(100),
    UNIVERSITY VARCHAR(100),
    TOTAL_STUDENTS NUMBER
);


SELECT * FROM STUDENT_RECORDS;
SELECT * FROM COLLEGE_RECORDS;


-- Shows the columns of both tables
DESC TABLE STUDENT_RECORDS;
DESC TABLE COLLEGE_RECORDS;


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- Puts sample rows into both tables
-- ============================================================

INSERT INTO STUDENT_RECORDS
    (STUDENT_ID, STUDENT_NAME, COURSE, CITY, MARKS)
VALUES
    (401, 'Kshitij', 'Data Engineering', 'Pune', 88),
    (402, 'Rahul', 'AWS Engineering', 'Mumbai', 81),
    (403, 'Amit', 'Data Analytics', 'Bangalore', 76),
    (404, 'Sneha', 'Data Engineering', 'Pune', 91),
    (405, 'Priya', 'Cloud Engineering', 'Hyderabad', 85);


INSERT INTO COLLEGE_RECORDS
    (COLLEGE_ID, COLLEGE_NAME, CITY, UNIVERSITY, TOTAL_STUDENTS)
VALUES
    (201, 'Fergusson College', 'Pune', 'Savitribai Phule Pune University', 12000),
    (202, 'St. Xaviers College', 'Mumbai', 'University of Mumbai', 9800),
    (203, 'Christ College', 'Bangalore', 'Bangalore University', 14500),
    (204, 'Loyola College', 'Chennai', 'University of Madras', 11000),
    (205, 'Osmania College', 'Hyderabad', 'Osmania University', 8700);


-- Checks the rows you just added
SELECT *
FROM STUDENT_RECORDS;


SELECT *
FROM COLLEGE_RECORDS;


-- ============================================================
-- 6. CREATE CSV FILE FORMAT
-- ONE format, used by the single stage
-- Says what the exported CSV files should look like
-- ============================================================

CREATE FILE FORMAT PARTITION_EXPORT_CSV_FORMAT
    TYPE = 'CSV'                        -- Saves the data as CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'  -- Puts double quotes around fields when needed
    SKIP_HEADER = 1                     -- Skips the header row when reading the file back
    COMPRESSION = 'NONE';               -- Keeps the file uncompressed


-- Shows the file formats that exist
SHOW FILE FORMATS;


-- ============================================================
-- 7. CREATE STORAGE INTEGRATION
-- ONE integration, because there is ONE bucket
-- This connects Snowflake to Amazon S3, so no keys are needed
--
-- BEFORE YOU START:
-- The AWS role SnowflakeS3PartitionExportSnowflakeRole must already exist.
-- Put its ARN into STORAGE_AWS_ROLE_ARN below.
--
-- No AWS access keys are stored in Snowflake. Snowflake borrows
-- the role through this integration instead.
--
-- STORAGE_ALLOWED_LOCATIONS is the bucket ROOT, not a single folder.
-- That is what allows BOTH the student/ and the college/ folder
-- inside the same bucket.
-- ============================================================

CREATE OR REPLACE STORAGE INTEGRATION S3_PARTITION_EXPORT_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN =
        'arn:aws:iam::772346609795:role/SnowflakeS3PartitionExportSnowflakeRole'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://snowflake-partition-export-2026/'
    );


-- ============================================================
-- 8. DESCRIBE STORAGE INTEGRATION
-- Shows the AWS IAM user and the external ID that Snowflake made
--
-- Copy STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID from
-- the output and put them into the trust policy of the AWS role
-- SnowflakeS3PartitionExportSnowflakeRole.
-- ============================================================

DESC INTEGRATION S3_PARTITION_EXPORT_INTEGRATION;


-- ============================================================
-- 9. CREATE EXTERNAL STAGE
-- ONE stage, pointing at the ROOT of the single bucket.
--
-- The stage does NOT point at student/ or college/. The folder
-- (the partition) is written in the COPY INTO path instead:
--     @PARTITION_S3_EXPORT_STAGE/student/student_records.csv
--     @PARTITION_S3_EXPORT_STAGE/college/college_records.csv
--
-- Snowflake creates those two folders automatically.
-- ============================================================

CREATE OR REPLACE STAGE PARTITION_S3_EXPORT_STAGE
    URL = 's3://snowflake-partition-export-2026/'
    STORAGE_INTEGRATION = S3_PARTITION_EXPORT_INTEGRATION
    FILE_FORMAT = PARTITION_EXPORT_CSV_FORMAT;


-- Shows the stages that exist
SHOW STAGES;


-- Shows the settings of the stage we made
DESC STAGE PARTITION_S3_EXPORT_STAGE;


-- ============================================================
-- 10. TEST S3 CONNECTIVITY
-- Lists the files that are in the bucket right now
--
-- "0 rows" is fine when no file has been exported yet.
-- What matters is that you do NOT get "Access Denied".
-- ============================================================

LIST @PARTITION_S3_EXPORT_STAGE;


-- ============================================================
-- 11. CREATE STORED PROCEDURE
-- ONE procedure that exports BOTH tables into the SAME bucket,
-- each one into its OWN folder (partition):
--   STUDENT_RECORDS -> student/student_records.csv
--   COLLEGE_RECORDS -> college/college_records.csv
-- AWS Lambda will call this procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE EXPORT_STUDENT_AND_COLLEGE_PARTITIONS_TO_S3()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN

    -- 1) Writes STUDENT_RECORDS to the student/ partition
    --    of the bucket as ONE file called student_records.csv
    COPY INTO @PARTITION_S3_EXPORT_STAGE/student/student_records.csv
    FROM STUDENT_RECORDS
    FILE_FORMAT = (
        FORMAT_NAME = 'PARTITION_EXPORT_CSV_FORMAT'
    )
    HEADER = TRUE       -- Writes the column names as the first row
    SINGLE = TRUE       -- Makes ONE file, not many part files
    OVERWRITE = TRUE;   -- Replaces the file if it is already there

    -- 2) Writes COLLEGE_RECORDS to the college/ partition
    --    of the bucket as ONE file called college_records.csv
    COPY INTO @PARTITION_S3_EXPORT_STAGE/college/college_records.csv
    FROM COLLEGE_RECORDS
    FILE_FORMAT = (
        FORMAT_NAME = 'PARTITION_EXPORT_CSV_FORMAT'
    )
    HEADER = TRUE
    SINGLE = TRUE
    OVERWRITE = TRUE;

    -- Sends a success message back to Lambda
    RETURN 'SUCCESS: STUDENT_RECORDS exported to student/student_records.csv and COLLEGE_RECORDS exported to college/college_records.csv';

END;
$$;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND
-- Who runs it : AWS Lambda — function snowflake-s3-partition-export-lambda
-- Why         : Lambda is the part that should start the export.
--               This procedure writes student_records.csv and
--               college_records.csv into the two partitions. If you run
--               the CALL yourself, the files are exported outside the
--               pipeline. Later, when you press Test in Lambda, you
--               cannot tell whether Lambda really did the work.
-- ============================================================

-- CALL EXPORT_STUDENT_AND_COLLEGE_PARTITIONS_TO_S3();   <-- left commented out on purpose
-- Lambda runs it with: cursor.execute("CALL EXPORT_STUDENT_AND_COLLEGE_PARTITIONS_TO_S3()")
