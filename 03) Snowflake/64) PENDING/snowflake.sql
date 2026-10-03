-- ============================================================
-- 64) S3 -> EventBridge -> Step Functions -> Snowflake SP1 -> SP2 Pipeline
--
-- WHAT THIS FILE MAKES
--   The Snowflake half of the pipeline:
--     * database, schema, warehouse
--     * storage integration + external stage, so Snowflake can READ the
--       CSV that lands in S3 (no AWS keys stored in Snowflake)
--     * STAGING_ORDERS  - the landing table SP1 fills
--     * DIM_CUSTOMER, DIM_PRODUCT, FACT_SALES - the star schema SP2 fills
--     * AUDIT_TABLE_1   - what SP1 did
--     * AUDIT_TABLE_2   - what SP2 did
--     * SP1_LOAD_STAGING      - step 1, loads ONE file from S3
--     * SP2_LOAD_STAR_SCHEMA  - step 2, staging -> dims + fact
--
-- Run the statements from top to bottom, once.
-- Lambda runs the two procedures, so do NOT call them by hand.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

CREATE DATABASE SNOWFLAKE_STEP_FUNCTIONS_PIPELINE;

USE DATABASE SNOWFLAKE_STEP_FUNCTIONS_PIPELINE;


-- ============================================================
-- 2. CREATE SCHEMA
-- ============================================================

CREATE SCHEMA PIPELINE_SCHEMA;

USE SCHEMA PIPELINE_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Makes a small XSMALL machine to run the SQL
-- ============================================================

CREATE WAREHOUSE PIPELINE_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60       -- Stops after 60 seconds with no work
    AUTO_RESUME = TRUE;     -- Starts again by itself when a query runs

USE WAREHOUSE PIPELINE_WH;


-- ============================================================
-- 4. CREATE CSV FILE FORMAT
-- Says how the incoming S3 CSV file must be read
-- ============================================================

CREATE FILE FORMAT RAW_ORDERS_CSV_FORMAT
    TYPE = 'CSV'                        -- The incoming file is CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'  -- Fields may be wrapped in double quotes
    SKIP_HEADER = 1                     -- The file has a header row to skip
    COMPRESSION = 'AUTO';               -- Reads plain or gzipped files

SHOW FILE FORMATS;


-- ============================================================
-- 5. CREATE STORAGE INTEGRATION
-- Lets Snowflake READ the S3 bucket, with no AWS keys stored in Snowflake.
--
-- BEFORE YOU START:
-- The AWS role SnowflakeStepFunctionsSnowflakeRole must already exist.
-- Put its ARN into STORAGE_AWS_ROLE_ARN below.
--
-- This role only needs READ access, because the file travels
-- S3 -> Snowflake here (the opposite direction of folder 63).
-- ============================================================

CREATE OR REPLACE STORAGE INTEGRATION S3_PIPELINE_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN =
        'arn:aws:iam::772346609795:role/SnowflakeStepFunctionsSnowflakeRole'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://snowflake-step-functions-pipeline-2026/raw/'
    );


-- ============================================================
-- 6. DESCRIBE STORAGE INTEGRATION
-- Shows the AWS IAM user and the external ID that Snowflake made
--
-- Copy STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID from the
-- output and put them into the trust policy of the AWS role
-- SnowflakeStepFunctionsSnowflakeRole.
-- ============================================================

DESC INTEGRATION S3_PIPELINE_INTEGRATION;


-- ============================================================
-- 7. CREATE EXTERNAL STAGE
-- Points at the raw/ folder of the S3 bucket, where the file arrives
-- ============================================================

CREATE OR REPLACE STAGE RAW_S3_PIPELINE_STAGE
    URL = 's3://snowflake-step-functions-pipeline-2026/raw/'
    STORAGE_INTEGRATION = S3_PIPELINE_INTEGRATION
    FILE_FORMAT = RAW_ORDERS_CSV_FORMAT;

SHOW STAGES;

DESC STAGE RAW_S3_PIPELINE_STAGE;


-- ============================================================
-- 8. TEST S3 CONNECTIVITY
-- Lists the files sitting in the raw/ folder right now
--
-- "0 rows" is fine before you upload a file. What matters is that you
-- do NOT get "Access Denied".
-- ============================================================

LIST @RAW_S3_PIPELINE_STAGE;


-- ============================================================
-- 9. CREATE STAGING TABLE
-- The landing table. SP1 fills this from the S3 file.
-- It is cleared at the start of every run, so it always holds the
-- file that just arrived.
-- ============================================================

CREATE TABLE STAGING_ORDERS (
    ORDER_ID NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY VARCHAR(100),
    PRODUCT_NAME VARCHAR(100),
    CATEGORY VARCHAR(100),
    QUANTITY NUMBER,
    PRICE NUMBER,
    ORDER_DATE DATE
);

DESC TABLE STAGING_ORDERS;


-- ============================================================
-- 10. CREATE THE STAR SCHEMA TABLES
-- SP2 fills these from STAGING_ORDERS.
-- ============================================================

-- One row per customer and city
CREATE TABLE DIM_CUSTOMER (
    CUSTOMER_KEY NUMBER AUTOINCREMENT,
    CUSTOMER_NAME VARCHAR(100),
    CITY VARCHAR(100)
);

-- One row per product and category
CREATE TABLE DIM_PRODUCT (
    PRODUCT_KEY NUMBER AUTOINCREMENT,
    PRODUCT_NAME VARCHAR(100),
    CATEGORY VARCHAR(100)
);

-- One row per order, pointing at one customer and one product
CREATE TABLE FACT_SALES (
    SALES_KEY NUMBER AUTOINCREMENT,
    ORDER_ID NUMBER,
    CUSTOMER_KEY NUMBER,
    PRODUCT_KEY NUMBER,
    QUANTITY NUMBER,
    AMOUNT NUMBER,
    ORDER_DATE DATE
);

DESC TABLE DIM_CUSTOMER;
DESC TABLE DIM_PRODUCT;
DESC TABLE FACT_SALES;


-- ============================================================
-- 11. CREATE THE TWO AUDIT TABLES
-- AUDIT_TABLE_1 -> one row per SP1 run
-- AUDIT_TABLE_2 -> one row per SP2 run
-- Lambda 2 reads AUDIT_TABLE_1 to report the real SP1 result.
-- ============================================================

CREATE TABLE AUDIT_TABLE_1 (
    RUN_ID NUMBER AUTOINCREMENT,
    FILE_NAME VARCHAR(500),
    ROWS_LOADED NUMBER,
    STATUS VARCHAR(20),
    MESSAGE VARCHAR(2000),
    STARTED_AT TIMESTAMP_NTZ,
    ENDED_AT TIMESTAMP_NTZ
);

CREATE TABLE AUDIT_TABLE_2 (
    RUN_ID NUMBER AUTOINCREMENT,
    ROWS_READ NUMBER,
    CUSTOMERS_LOADED NUMBER,
    PRODUCTS_LOADED NUMBER,
    FACTS_LOADED NUMBER,
    STATUS VARCHAR(20),
    MESSAGE VARCHAR(2000),
    STARTED_AT TIMESTAMP_NTZ,
    ENDED_AT TIMESTAMP_NTZ
);

DESC TABLE AUDIT_TABLE_1;
DESC TABLE AUDIT_TABLE_2;


-- ============================================================
-- 12. CREATE SP1 - LOAD THE S3 FILE INTO STAGING
-- Called by Lambda 1 (function snowflake-sp1-start-lambda),
-- asynchronously.
--
-- P_FILE_NAME is the file name inside the stage folder, for example
-- orders_2026_10_03.csv. Lambda takes it from the S3 event, so SP1
-- loads exactly the file that just arrived.
--
-- The COPY INTO is built with EXECUTE IMMEDIATE so the file name can be
-- concatenated into the statement.
-- ============================================================

CREATE OR REPLACE PROCEDURE SP1_LOAD_STAGING(P_FILE_NAME STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    V_STARTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP();
    V_ENDED_AT TIMESTAMP_NTZ;
    V_ROWS_LOADED NUMBER DEFAULT 0;
BEGIN

    -- 1) Clears the landing table, so the run only holds this one file
    TRUNCATE TABLE IF EXISTS STAGING_ORDERS;

    -- 2) Loads exactly the file that landed in S3.
    --    FORCE = TRUE re-loads it even if Snowflake already has it in
    --    the load history, so the same file can be replayed.
    EXECUTE IMMEDIATE
        'COPY INTO STAGING_ORDERS ' ||
        'FROM @RAW_S3_PIPELINE_STAGE/' || :P_FILE_NAME || ' ' ||
        'FILE_FORMAT = (FORMAT_NAME = ''RAW_ORDERS_CSV_FORMAT'') ' ||
        'FORCE = TRUE';

    -- 3) Counts what is now in the landing table
    SELECT COUNT(*)
      INTO :V_ROWS_LOADED
      FROM STAGING_ORDERS;

    V_ENDED_AT := CURRENT_TIMESTAMP();

    -- 4) Records the run in AUDIT_TABLE_1
    INSERT INTO AUDIT_TABLE_1
        (FILE_NAME, ROWS_LOADED, STATUS, MESSAGE, STARTED_AT, ENDED_AT)
    VALUES
        (
            :P_FILE_NAME,
            :V_ROWS_LOADED,
            'SUCCESS',
            'SP1 loaded the file into STAGING_ORDERS',
            :V_STARTED_AT,
            :V_ENDED_AT
        );

    RETURN 'SUCCESS: ' || :V_ROWS_LOADED || ' rows loaded from ' || :P_FILE_NAME;

EXCEPTION
    WHEN OTHER THEN

        -- Records the failure and returns FAILED instead of raising.
        -- The audit row therefore survives, and Lambda 2 reads it to
        -- report the real result of the run.
        V_ENDED_AT := CURRENT_TIMESTAMP();

        INSERT INTO AUDIT_TABLE_1
            (FILE_NAME, ROWS_LOADED, STATUS, MESSAGE, STARTED_AT, ENDED_AT)
        VALUES
            (
                :P_FILE_NAME,
                0,
                'FAILURE',
                :SQLERRM,
                :V_STARTED_AT,
                :V_ENDED_AT
            );

        RETURN 'FAILED: ' || :SQLERRM;

END;
$$;


-- ============================================================
-- 13. CREATE SP2 - LOAD THE STAR SCHEMA
-- Called by Lambda 3 (function snowflake-sp2-run-lambda) after SP1
-- has succeeded.
--
-- Reads STAGING_ORDERS and:
--   * inserts any new customer into DIM_CUSTOMER
--   * inserts any new product  into DIM_PRODUCT
--   * inserts the orders       into FACT_SALES
--   * checks that every staged order really reached the fact table
--   * records the run in AUDIT_TABLE_2
--
-- The NOT EXISTS checks make the procedure safe to run twice: the
-- second run adds nothing.
-- ============================================================

CREATE OR REPLACE PROCEDURE SP2_LOAD_STAR_SCHEMA()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    V_STARTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP();
    V_ENDED_AT TIMESTAMP_NTZ;
    V_ROWS_READ NUMBER DEFAULT 0;
    V_CUSTOMERS NUMBER DEFAULT 0;
    V_PRODUCTS NUMBER DEFAULT 0;
    V_FACTS NUMBER DEFAULT 0;
    V_MISSING_FACTS NUMBER DEFAULT 0;
BEGIN

    SELECT COUNT(*)
      INTO :V_ROWS_READ
      FROM STAGING_ORDERS;

    -- 1) Nothing to transform means the run is a failure, not a success
    IF (:V_ROWS_READ = 0) THEN

        V_ENDED_AT := CURRENT_TIMESTAMP();

        INSERT INTO AUDIT_TABLE_2
            (ROWS_READ, CUSTOMERS_LOADED, PRODUCTS_LOADED, FACTS_LOADED,
             STATUS, MESSAGE, STARTED_AT, ENDED_AT)
        VALUES
            (0, 0, 0, 0, 'FAILURE',
             'STAGING_ORDERS is empty. SP1 had nothing to hand over.',
             :V_STARTED_AT, :V_ENDED_AT);

        RETURN 'FAILED: STAGING_ORDERS is empty';

    END IF;

    -- 2) Adds only the customers that are not in the dimension yet
    INSERT INTO DIM_CUSTOMER (CUSTOMER_NAME, CITY)
    SELECT DISTINCT
        s.CUSTOMER_NAME,
        s.CITY
    FROM STAGING_ORDERS s
    WHERE NOT EXISTS (
        SELECT 1
        FROM DIM_CUSTOMER d
        WHERE d.CUSTOMER_NAME = s.CUSTOMER_NAME
          AND d.CITY = s.CITY
    );

    V_CUSTOMERS := SQLROWCOUNT;

    -- 3) Adds only the products that are not in the dimension yet
    INSERT INTO DIM_PRODUCT (PRODUCT_NAME, CATEGORY)
    SELECT DISTINCT
        s.PRODUCT_NAME,
        s.CATEGORY
    FROM STAGING_ORDERS s
    WHERE NOT EXISTS (
        SELECT 1
        FROM DIM_PRODUCT d
        WHERE d.PRODUCT_NAME = s.PRODUCT_NAME
          AND d.CATEGORY = s.CATEGORY
    );

    V_PRODUCTS := SQLROWCOUNT;

    -- 4) Adds the facts, looking up the keys from the dimensions.
    --    The WHERE NOT EXISTS keeps a re-run from duplicating orders.
    INSERT INTO FACT_SALES
        (ORDER_ID, CUSTOMER_KEY, PRODUCT_KEY, QUANTITY, AMOUNT, ORDER_DATE)
    SELECT
        s.ORDER_ID,
        c.CUSTOMER_KEY,
        p.PRODUCT_KEY,
        s.QUANTITY,
        s.QUANTITY * s.PRICE,
        s.ORDER_DATE
    FROM STAGING_ORDERS s
    JOIN DIM_CUSTOMER c
      ON c.CUSTOMER_NAME = s.CUSTOMER_NAME
     AND c.CITY = s.CITY
    JOIN DIM_PRODUCT p
      ON p.PRODUCT_NAME = s.PRODUCT_NAME
     AND p.CATEGORY = s.CATEGORY
    WHERE NOT EXISTS (
        SELECT 1
        FROM FACT_SALES f
        WHERE f.ORDER_ID = s.ORDER_ID
    );

    V_FACTS := SQLROWCOUNT;

    -- 5) Validation: every staged order must have reached the fact table
    SELECT COUNT(*)
      INTO :V_MISSING_FACTS
      FROM STAGING_ORDERS s
      WHERE NOT EXISTS (
        SELECT 1
        FROM FACT_SALES f
        WHERE f.ORDER_ID = s.ORDER_ID
      );

    V_ENDED_AT := CURRENT_TIMESTAMP();

    IF (:V_MISSING_FACTS > 0) THEN

        INSERT INTO AUDIT_TABLE_2
            (ROWS_READ, CUSTOMERS_LOADED, PRODUCTS_LOADED, FACTS_LOADED,
             STATUS, MESSAGE, STARTED_AT, ENDED_AT)
        VALUES
            (:V_ROWS_READ, :V_CUSTOMERS, :V_PRODUCTS, :V_FACTS, 'FAILURE',
             :V_MISSING_FACTS || ' staged orders did not reach FACT_SALES',
             :V_STARTED_AT, :V_ENDED_AT);

        RETURN 'FAILED: ' || :V_MISSING_FACTS || ' staged orders did not reach FACT_SALES';

    END IF;

    -- 6) Everything lined up, so the run is a success
    INSERT INTO AUDIT_TABLE_2
        (ROWS_READ, CUSTOMERS_LOADED, PRODUCTS_LOADED, FACTS_LOADED,
         STATUS, MESSAGE, STARTED_AT, ENDED_AT)
    VALUES
        (:V_ROWS_READ, :V_CUSTOMERS, :V_PRODUCTS, :V_FACTS, 'SUCCESS',
         'SP2 loaded the dimensions and the fact table',
         :V_STARTED_AT, :V_ENDED_AT);

    RETURN 'SUCCESS: ' || :V_FACTS || ' rows loaded into FACT_SALES';

EXCEPTION
    WHEN OTHER THEN

        V_ENDED_AT := CURRENT_TIMESTAMP();

        INSERT INTO AUDIT_TABLE_2
            (ROWS_READ, CUSTOMERS_LOADED, PRODUCTS_LOADED, FACTS_LOADED,
             STATUS, MESSAGE, STARTED_AT, ENDED_AT)
        VALUES
            (:V_ROWS_READ, 0, 0, 0, 'FAILURE',
             :SQLERRM, :V_STARTED_AT, :V_ENDED_AT);

        RETURN 'FAILED: ' || :SQLERRM;

END;
$$;


-- ============================================================
-- 14. CHECK THE RESULTS AFTER A RUN
-- Use these once the pipeline has run through Step Functions.
-- ============================================================

-- SELECT * FROM AUDIT_TABLE_1 ORDER BY RUN_ID DESC;
-- SELECT * FROM AUDIT_TABLE_2 ORDER BY RUN_ID DESC;
-- SELECT * FROM STAGING_ORDERS;
-- SELECT * FROM DIM_CUSTOMER;
-- SELECT * FROM DIM_PRODUCT;
-- SELECT * FROM FACT_SALES;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENTS BELOW BY HAND
-- Who runs them : AWS Lambda, started by Step Functions
--   Lambda 1 (snowflake-sp1-start-lambda) -> SP1_LOAD_STAGING
--   Lambda 3 (snowflake-sp2-run-lambda)   -> SP2_LOAD_STAR_SCHEMA
--
-- Why: the whole point of the pipeline is that Step Functions starts
--      SP1, waits, checks it, and then starts SP2. If you run the
--      procedures yourself, the audit tables fill up with rows that no
--      pipeline run produced, and you cannot tell whether the state
--      machine really did the work.
-- ============================================================

-- CALL SP1_LOAD_STAGING('orders_2026_10_03.csv');   <-- left commented out on purpose
-- CALL SP2_LOAD_STAR_SCHEMA();                      <-- left commented out on purpose
