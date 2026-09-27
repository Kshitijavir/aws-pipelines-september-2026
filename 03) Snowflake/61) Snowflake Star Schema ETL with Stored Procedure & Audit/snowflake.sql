-- ============================================================
-- 61) Snowflake - Star Schema ETL with Stored Procedure & Audit
-- All the SQL for this pipeline, in README order.
-- Paste the whole file into a Snowflake worksheet and run it.
--
-- A star schema is one big table in the middle (FACT_SALES).
-- The smaller tables around it are the dimensions (DIM_CUSTOMER).
-- The audit table (AUDIT_LOG) records what the job did.
--
-- SP2 is created first, but SP1 is run first. SP1 calls SP2 for you.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE AND SCHEMA
-- Makes the database and the schema for this pipeline
-- ============================================================

CREATE DATABASE SNOWFLAKE_STAR_SCHEMA_PRACTICE;

USE DATABASE SNOWFLAKE_STAR_SCHEMA_PRACTICE;

CREATE SCHEMA STAR_SCHEMA;

USE SCHEMA STAR_SCHEMA;


-- ============================================================
-- STEP 2. CREATE WAREHOUSE
-- Makes the machine that runs the SQL
-- ============================================================

CREATE WAREHOUSE STAR_WH
    WAREHOUSE_SIZE = XSMALL;

USE WAREHOUSE STAR_WH;


-- ============================================================
-- STEP 3. CREATE THE CSV FILE FORMAT
-- Tells Snowflake what the CSV file looks like, so it can read it
-- ============================================================

CREATE FILE FORMAT CUSTOMER_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';


-- ============================================================
-- STEP 4. CREATE THE STAGE
-- A stage is the inbox where you put the CSV file
-- ============================================================

CREATE STAGE CUSTOMER_STAGE
    FILE_FORMAT = CUSTOMER_CSV_FORMAT;


-- ============================================================
-- STEP 5. CREATE THE HOLDING (STAGING) TABLE
-- Holds the raw rows from the CSV before they are cleaned
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

SELECT * FROM CUSTOMER_STAGING;


-- ============================================================
-- STEP 6. CREATE THE CUSTOMER DIMENSION
-- The small table that says who the customer is
-- ============================================================

CREATE TABLE DIM_CUSTOMER (
    CUSTOMER_KEY  NUMBER AUTOINCREMENT,
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    CITY          VARCHAR(100),
    COUNTRY       VARCHAR(100)
);

SELECT * FROM DIM_CUSTOMER;


-- ============================================================
-- STEP 7. CREATE THE FACT TABLE
-- The big middle table that holds the numbers you add up
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

SELECT * FROM FACT_SALES;


-- ============================================================
-- STEP 8. CREATE THE AUDIT TABLE
-- The record of what the job did: counts, times, status, errors
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

SELECT * FROM AUDIT_LOG;


-- ============================================================
-- STEP 9. CHECK THE UPLOADED FILE
-- Upload customer_sales.csv into CUSTOMER_STAGE by hand first
-- (Snowsight: the stage -> Upload). Then run this to check it landed
-- ============================================================

LIST @CUSTOMER_STAGE;


-- ============================================================
-- STEP 10. WHY SP2 IS CREATED FIRST
-- Create the procedures in this order: SP2, then SP1.
-- Run them in this order: SP1, then SP2, because SP1 calls SP2.
--
-- Why? SP1 contains CALL SP_LOAD_STAR_SCHEMA(). So SP2 must already
-- exist before Snowflake can build SP1. There is nothing to run here.
-- ============================================================


-- ============================================================
-- STEP 11. CREATE SP2 FIRST
-- SP2 fills DIM_CUSTOMER and FACT_SALES from CUSTOMER_STAGING,
-- checks the counts and writes a row to AUDIT_LOG
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
    -- STEP 1: Count the rows in staging
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :STAGING_COUNT
    FROM CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 2: Fill the customer table
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
    -- STEP 3: Fill the sales table
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
    -- STEP 4: Count the customer rows
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :DIM_COUNT
    FROM DIM_CUSTOMER;


    ------------------------------------------------
    -- STEP 5: Count the sales rows
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :FACT_COUNT
    FROM FACT_SALES;


    ------------------------------------------------
    -- STEP 6: Compare the two counts
    ------------------------------------------------

    IF (STAGING_COUNT = FACT_COUNT) THEN
        RECON_STATUS := 'MATCH';
    ELSE
        RECON_STATUS := 'MISMATCH';
    END IF;


    ------------------------------------------------
    -- STEP 7: Note the end time
    ------------------------------------------------

    END_TIME := CURRENT_TIMESTAMP();


    ------------------------------------------------
    -- STEP 8: Write the audit row for SP2
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
-- SP1 is the main procedure. It empties the staging table, copies the
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
    -- STEP 1: Empty the staging table
    ------------------------------------------------

    TRUNCATE TABLE CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 2: Copy the file from the stage into staging
    ------------------------------------------------

    COPY INTO CUSTOMER_STAGING
    FROM @CUSTOMER_STAGE
    FILE_FORMAT = (
        FORMAT_NAME = 'CUSTOMER_CSV_FORMAT'
    );


    ------------------------------------------------
    -- STEP 3: Count the rows in staging
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :SOURCE_COUNT
    FROM CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 4: Note the end time
    ------------------------------------------------

    END_TIME := CURRENT_TIMESTAMP();


    ------------------------------------------------
    -- STEP 5: Write the audit row for SP1
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
    -- STEP 6: Run SP2
    ------------------------------------------------

    CALL SP_LOAD_STAR_SCHEMA();


    RETURN 'SP1 COMPLETED SUCCESSFULLY';

END;
$$;

-- Shows the two procedures you just created
SHOW PROCEDURES;


-- ============================================================
-- STEP 13. START THE PIPELINE
-- Run SP1 only. It does the whole job and it calls SP2 for you
-- ============================================================

CALL SP_LOAD_STAGING();


-- ============================================================
-- STEP 14. WHAT HAPPENS INSIDE
-- The CALL above makes SP1 empty the staging table, copy the file from
-- the stage, write its own audit row and then call SP2. SP2 fills
-- DIM_CUSTOMER and FACT_SALES and writes the second audit row.
-- There is nothing to run in this step.
-- ============================================================


-- ============================================================
-- STEP 15. CHECK THE STAGING TABLE
-- Should show 5 rows (the raw rows from the CSV)
-- ============================================================

SELECT * FROM CUSTOMER_STAGING;


-- ============================================================
-- STEP 16. CHECK THE DIMENSION
-- Should show 4 customers, because Rahul is only one customer
-- ============================================================

SELECT * FROM DIM_CUSTOMER ORDER BY CUSTOMER_KEY;


-- ============================================================
-- STEP 17. CHECK THE FACT TABLE
-- Should show 5 sales, one for every line in the CSV
-- ============================================================

SELECT * FROM FACT_SALES ORDER BY SALES_KEY;


-- ============================================================
-- STEP 18. CHECK THE AUDIT LOG
-- Shows one row from SP1 and one from SP2, with the counts and the
-- match result (SP1 writes PENDING, SP2 writes MATCH)
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
