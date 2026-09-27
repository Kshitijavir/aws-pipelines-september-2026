-- ============================================================
-- 61) Snowflake - Star Schema ETL with Stored Procedure & Audit
-- Every SQL statement for this pipeline, in README order.
-- Paste the whole file into a Snowflake worksheet and run it.
--
-- A star schema is one big table in the middle (FACT_SALES) with
-- smaller tables around it (DIM_CUSTOMER). The audit table
-- (AUDIT_LOG) is the record of what the job did.
--
-- SP2 is created first, but SP1 is run first. SP1 calls SP2 for you.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE AND SCHEMA
-- Creates the big box (database) and the folder (schema) for this pipeline
-- ============================================================

CREATE DATABASE SNOWFLAKE_STAR_SCHEMA_PRACTICE;

USE DATABASE SNOWFLAKE_STAR_SCHEMA_PRACTICE;

CREATE SCHEMA STAR_SCHEMA;

USE SCHEMA STAR_SCHEMA;


-- ============================================================
-- STEP 2. CREATE WAREHOUSE
-- Creates the machine that runs the SQL
-- ============================================================

CREATE WAREHOUSE STAR_WH
    WAREHOUSE_SIZE = XSMALL;

USE WAREHOUSE STAR_WH;


-- ============================================================
-- STEP 3. CREATE THE CSV FILE FORMAT
-- Tells Snowflake how the CSV file looks, so it can read it
-- ============================================================

CREATE FILE FORMAT CUSTOMER_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';


-- ============================================================
-- STEP 4. CREATE THE STAGE
-- The stage is the landing spot (inbox) where the CSV file is uploaded
-- ============================================================

CREATE STAGE CUSTOMER_STAGE
    FILE_FORMAT = CUSTOMER_CSV_FORMAT;

-- Shows the files that are sitting in the stage
LIST @CUSTOMER_STAGE;


-- ============================================================
-- STEP 5. CREATE THE HOLDING (STAGING) TABLE
-- Keeps the raw rows from the CSV before they are cleaned
-- ============================================================

CREATE TABLE CUSTOMER_STAGING (
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    CITY          VARCHAR(100),
    COUNTRY       VARCHAR(100),
    PRODUCT       VARCHAR(100),
    QUANTITY      NUMBER,
    UNIT_PRICE    NUMBER,
    ORDER_DATE    DATE
);


-- ============================================================
-- STEP 6. CREATE THE CUSTOMER DIMENSION
-- The small table that describes who the customer is
-- ============================================================

CREATE TABLE DIM_CUSTOMER (
    CUSTOMER_KEY  NUMBER AUTOINCREMENT,
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    CITY          VARCHAR(100),
    COUNTRY       VARCHAR(100)
);


-- ============================================================
-- STEP 7. CREATE THE FACT TABLE
-- The big table in the middle that holds the numbers you add up
-- ============================================================

CREATE TABLE FACT_SALES (
    SALES_KEY    NUMBER AUTOINCREMENT,
    CUSTOMER_KEY NUMBER,
    PRODUCT      VARCHAR(100),
    QUANTITY     NUMBER,
    UNIT_PRICE   NUMBER,
    TOTAL_AMOUNT NUMBER,
    ORDER_DATE   DATE
);


-- ============================================================
-- STEP 8. CREATE THE AUDIT TABLE
-- The record of what the job did: counts, times, status and errors
-- ============================================================

CREATE TABLE AUDIT_LOG (
    AUDIT_ID NUMBER AUTOINCREMENT,

    PIPELINE_NAME  VARCHAR(100),
    PROCEDURE_NAME VARCHAR(100),

    START_TIME       TIMESTAMP,
    END_TIME         TIMESTAMP,
    DURATION_SECONDS NUMBER,

    STAGING_RECORDS      NUMBER,
    DIM_CUSTOMER_RECORDS NUMBER,
    FACT_SALES_RECORDS   NUMBER,

    RECONCILIATION_STATUS VARCHAR(30),

    STATUS VARCHAR(30),

    ERROR_MESSAGE VARCHAR(1000),

    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);


-- ============================================================
-- STEP 9. CHECK THE UPLOADED FILE
-- Upload customer_sales.csv into CUSTOMER_STAGE by hand first
-- (Snowsight: the stage -> Upload). Then run this to confirm it landed
-- ============================================================

LIST @CUSTOMER_STAGE;


-- ============================================================
-- STEP 10. WHY SP2 IS CREATED FIRST
-- Order to CREATE the procedures: SP2, then SP1. Order to RUN them:
-- SP1, then SP2, because SP1 calls SP2 for you.
--
-- Why? SP1 contains CALL SP_LOAD_STAR_SCHEMA(). So SP2 must already
-- exist before Snowflake can build SP1. There is no statement to
-- run in this step.
-- ============================================================


-- ============================================================
-- STEP 11. CREATE SP2 FIRST
-- SP2 loads the star schema: it fills DIM_CUSTOMER and FACT_SALES
-- from CUSTOMER_STAGING, checks the counts and writes to AUDIT_LOG
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_LOAD_STAR_SCHEMA()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE

    START_TIME TIMESTAMP;
    END_TIME TIMESTAMP;

    STAGING_COUNT NUMBER;
    DIM_COUNT NUMBER;
    FACT_COUNT NUMBER;

    RECON_STATUS VARCHAR;

BEGIN

    START_TIME := CURRENT_TIMESTAMP();

    ------------------------------------------------
    -- STEP 1: Count staging records
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :STAGING_COUNT
    FROM CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 2: Load Customer Dimension
    ------------------------------------------------

    INSERT INTO DIM_CUSTOMER
    (
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CITY,
        COUNTRY
    )
    SELECT DISTINCT
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CITY,
        COUNTRY
    FROM CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 3: Load Fact Table
    ------------------------------------------------

    INSERT INTO FACT_SALES
    (
        CUSTOMER_KEY,
        PRODUCT,
        QUANTITY,
        UNIT_PRICE,
        TOTAL_AMOUNT,
        ORDER_DATE
    )
    SELECT
        D.CUSTOMER_KEY,
        S.PRODUCT,
        S.QUANTITY,
        S.UNIT_PRICE,
        S.QUANTITY * S.UNIT_PRICE,
        S.ORDER_DATE
    FROM CUSTOMER_STAGING S
    JOIN DIM_CUSTOMER D
        ON S.CUSTOMER_ID = D.CUSTOMER_ID;


    ------------------------------------------------
    -- STEP 4: Count Dimension
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :DIM_COUNT
    FROM DIM_CUSTOMER;


    ------------------------------------------------
    -- STEP 5: Count Fact
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :FACT_COUNT
    FROM FACT_SALES;


    ------------------------------------------------
    -- STEP 6: Reconciliation
    ------------------------------------------------

    IF (STAGING_COUNT = FACT_COUNT) THEN
        RECON_STATUS := 'MATCH';
    ELSE
        RECON_STATUS := 'MISMATCH';
    END IF;


    ------------------------------------------------
    -- STEP 7: End Time
    ------------------------------------------------

    END_TIME := CURRENT_TIMESTAMP();


    ------------------------------------------------
    -- STEP 8: Audit SP2
    ------------------------------------------------

    INSERT INTO AUDIT_LOG
    (
        PIPELINE_NAME,
        PROCEDURE_NAME,
        START_TIME,
        END_TIME,
        DURATION_SECONDS,
        STAGING_RECORDS,
        DIM_CUSTOMER_RECORDS,
        FACT_SALES_RECORDS,
        RECONCILIATION_STATUS,
        STATUS,
        ERROR_MESSAGE
    )
    VALUES
    (
        'CUSTOMER_STAR_SCHEMA_PIPELINE',
        'SP_LOAD_STAR_SCHEMA',
        :START_TIME,
        :END_TIME,
        DATEDIFF('SECOND', :START_TIME, :END_TIME),
        :STAGING_COUNT,
        :DIM_COUNT,
        :FACT_COUNT,
        :RECON_STATUS,
        'SUCCESS',
        NULL
    );


    RETURN 'SP2 COMPLETED SUCCESSFULLY';

END;
$$;


-- ============================================================
-- STEP 12. NOW CREATE SP1
-- SP1 is the main procedure: it clears the staging table, copies the
-- file from the stage, writes its own audit row, then calls SP2
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_LOAD_STAGING()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE

    START_TIME TIMESTAMP;
    END_TIME TIMESTAMP;

    SOURCE_COUNT NUMBER;

BEGIN

    START_TIME := CURRENT_TIMESTAMP();


    ------------------------------------------------
    -- STEP 1: Clear previous staging data
    ------------------------------------------------

    TRUNCATE TABLE CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 2: Stage → Staging
    ------------------------------------------------

    COPY INTO CUSTOMER_STAGING
    FROM @CUSTOMER_STAGE
    FILE_FORMAT = (
        FORMAT_NAME = 'CUSTOMER_CSV_FORMAT'
    );


    ------------------------------------------------
    -- STEP 3: Count staging records
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :SOURCE_COUNT
    FROM CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 4: End time
    ------------------------------------------------

    END_TIME := CURRENT_TIMESTAMP();


    ------------------------------------------------
    -- STEP 5: Audit SP1
    ------------------------------------------------

    INSERT INTO AUDIT_LOG
    (
        PIPELINE_NAME,
        PROCEDURE_NAME,
        START_TIME,
        END_TIME,
        DURATION_SECONDS,
        STAGING_RECORDS,
        DIM_CUSTOMER_RECORDS,
        FACT_SALES_RECORDS,
        RECONCILIATION_STATUS,
        STATUS,
        ERROR_MESSAGE
    )
    VALUES
    (
        'CUSTOMER_STAR_SCHEMA_PIPELINE',
        'SP_LOAD_STAGING',
        :START_TIME,
        :END_TIME,
        DATEDIFF('SECOND', :START_TIME, :END_TIME),
        :SOURCE_COUNT,
        NULL,
        NULL,
        'PENDING',
        'SUCCESS',
        NULL
    );


    ------------------------------------------------
    -- STEP 6: Call SP2
    ------------------------------------------------

    CALL SP_LOAD_STAR_SCHEMA();


    RETURN 'SP1 COMPLETED SUCCESSFULLY';

END;
$$;

-- Shows both procedures you just created
SHOW PROCEDURES;


-- ============================================================
-- STEP 13. START THE PIPELINE
-- Run SP1 only. It does the whole job, and it calls SP2 for you
-- ============================================================

CALL SP_LOAD_STAGING();


-- ============================================================
-- STEP 14. WHAT HAPPENS INSIDE
-- Running the CALL above makes SP1 empty the staging table, copy the file
-- from the stage, write its own audit row and then call SP2. SP2 fills
-- DIM_CUSTOMER and FACT_SALES and writes the second audit row.
-- There is no statement to run in this step.
-- ============================================================


-- ============================================================
-- STEP 15. CHECK THE STAGING TABLE
-- Should show 5 rows (the raw rows from the CSV)
-- ============================================================

SELECT * FROM CUSTOMER_STAGING;


-- ============================================================
-- STEP 16. CHECK THE DIMENSION
-- Should show 4 customers, because Rahul is one customer
-- ============================================================

SELECT * FROM DIM_CUSTOMER ORDER BY CUSTOMER_KEY;


-- ============================================================
-- STEP 17. CHECK THE FACT TABLE
-- Should show 5 sales, one for every line in the CSV
-- ============================================================

SELECT * FROM FACT_SALES ORDER BY SALES_KEY;


-- ============================================================
-- STEP 18. CHECK THE AUDIT LOG
-- Shows one row from SP1 and one row from SP2, with the counts and the
-- reconciliation result (SP1 writes PENDING, SP2 writes MATCH)
-- ============================================================

SELECT * FROM AUDIT_LOG ORDER BY AUDIT_ID;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND
-- Who runs it : Stored procedure SP_LOAD_STAGING (SP1) runs it for you
-- Why         : SP1 already calls SP2 at the end. If you run SP2 by hand
--               as well, the dimension, the fact table and the audit log
--               are written a second time and the counts no longer match.
-- ============================================================

-- CALL SP_LOAD_STAR_SCHEMA();      <-- left commented out on purpose
