-- ============================================================
-- 60) End-to-End Snowflake Data Pipeline
-- Every SQL statement for this pipeline, in the same order as the README.
-- Paste this whole file into a Snowflake worksheet.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- Creates the big box that holds everything below
-- ============================================================

CREATE DATABASE SNOWFLAKE_END_TO_END_PRACTICE;


-- Selects the database for the remaining operations
USE DATABASE SNOWFLAKE_END_TO_END_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Creates a folder inside the database to keep the objects together
-- ============================================================

CREATE SCHEMA E2E_SCHEMA;


-- Selects the schema for the remaining operations
USE SCHEMA E2E_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Creates the machine that runs the SQL and does the loading
-- ============================================================

CREATE WAREHOUSE E2E_WH
    WAREHOUSE_SIZE = XSMALL;


-- Selects the warehouse used to execute queries
USE WAREHOUSE E2E_WH;


-- ============================================================
-- 4. CREATE THE RAW TABLE
-- Holds the CSV data exactly as it comes in from the file
-- ============================================================

CREATE TABLE CUSTOMER_RAW (
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY          VARCHAR(100),
    SALARY        NUMBER
);


-- ============================================================
-- 5. CREATE THE FILE FORMAT
-- Tells Snowflake how to read the CSV file
-- ============================================================

CREATE FILE FORMAT CUSTOMER_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';


-- ============================================================
-- 6. CREATE THE STAGE
-- The landing area that holds the uploaded CSV file
-- ============================================================

CREATE STAGE CUSTOMER_STAGE
    FILE_FORMAT = CUSTOMER_CSV_FORMAT;


-- ============================================================
-- 7. CREATE THE FINAL TABLE
-- Holds the cleaned-up data with the salary category column
-- ============================================================

CREATE TABLE CUSTOMER_FINAL (
    CUSTOMER_ID     NUMBER,
    CUSTOMER_NAME   VARCHAR(100),
    CITY            VARCHAR(100),
    SALARY          NUMBER,
    SALARY_CATEGORY VARCHAR(20)
);


-- ============================================================
-- 8. CHECK THE UPLOADED FILE
-- Upload customer.csv to CUSTOMER_STAGE in Snowsight first,
-- then lists the files sitting in the stage
-- ============================================================

LIST @CUSTOMER_STAGE;


-- ============================================================
-- 9. LOAD THE CSV INTO THE RAW TABLE
-- Loads the CSV from the stage into the raw table
-- ============================================================

COPY INTO CUSTOMER_RAW
FROM @CUSTOMER_STAGE;


-- Checks the rows loaded into the raw table
SELECT * FROM CUSTOMER_RAW;


-- ============================================================
-- 10. TRANSFORM THE DATA
-- Copies the raw rows into the final table, uppercases the names
-- and cities, and adds the salary category
-- ============================================================

INSERT INTO CUSTOMER_FINAL
SELECT
    CUSTOMER_ID,
    UPPER(CUSTOMER_NAME),
    UPPER(CITY),
    SALARY,
    CASE
        WHEN SALARY >= 90000 THEN 'HIGH'
        WHEN SALARY >= 60000 THEN 'MEDIUM'
        ELSE 'LOW'
    END
FROM CUSTOMER_RAW;


-- ============================================================
-- 11. CHECK THE FINAL TABLE
-- Shows the cleaned-up rows with their salary category
-- ============================================================

SELECT * FROM CUSTOMER_FINAL ORDER BY CUSTOMER_ID;
