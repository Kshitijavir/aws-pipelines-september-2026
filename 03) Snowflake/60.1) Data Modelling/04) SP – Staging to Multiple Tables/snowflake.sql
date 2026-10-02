-- ============================================================
-- 60.1) Data Modelling - 04) SP - Staging to Multiple Tables
-- All the SQL for this practice, in one file.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- One STAGING table -> five tables:
--   CUSTOMER, PRODUCT, LOCATION, PROVIDER, CLAIM
--
-- 1. We load 30 records into STAGING.
-- 2. First we load the 5 tables by hand (without an SP).
-- 3. Then we save all 5 statements inside one Stored Procedure.
-- 4. Then we run the SP with one short CALL line.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- The big box that holds everything for this practice
-- ============================================================

CREATE DATABASE IF NOT EXISTS SP_MULTI_TABLE_PRACTICE;

-- Uses this database for the next statements
USE DATABASE SP_MULTI_TABLE_PRACTICE;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- A folder that keeps this practice's tables together
-- ============================================================

CREATE SCHEMA IF NOT EXISTS SP_MULTI_SCHEMA;

-- Uses this schema for the next statements
USE SCHEMA SP_MULTI_SCHEMA;


-- ============================================================
-- STEP 3. CREATE THE STAGING TABLE
-- This is the MAIN source table. All 10 columns sit here
-- ============================================================

CREATE OR REPLACE TABLE STAGING (
    CUSTOMER_ID   INT,
    CUSTOMER_NAME VARCHAR,
    PRODUCT_ID    INT,
    PRODUCT_NAME  VARCHAR,
    LOCATION_ID   INT,
    LOCATION_NAME VARCHAR,
    PROVIDER_ID   INT,
    PROVIDER_NAME VARCHAR,
    CLAIM_ID      INT,
    CLAIM_AMOUNT  NUMBER
);

-- Shows the table (it is empty now)
SELECT * FROM STAGING;


-- ============================================================
-- STEP 4. CREATE THE CUSTOMER TABLE
-- Takes only 2 columns from STAGING
-- ============================================================

CREATE OR REPLACE TABLE CUSTOMER (
    CUSTOMER_ID   INT,
    CUSTOMER_NAME VARCHAR
);

SELECT * FROM CUSTOMER;


-- ============================================================
-- STEP 5. CREATE THE PRODUCT TABLE
-- Takes only 2 columns from STAGING
-- ============================================================

CREATE OR REPLACE TABLE PRODUCT (
    PRODUCT_ID   INT,
    PRODUCT_NAME VARCHAR
);

SELECT * FROM PRODUCT;


-- ============================================================
-- STEP 6. CREATE THE LOCATION TABLE
-- Takes only 2 columns from STAGING
-- ============================================================

CREATE OR REPLACE TABLE LOCATION (
    LOCATION_ID   INT,
    LOCATION_NAME VARCHAR
);

SELECT * FROM LOCATION;


-- ============================================================
-- STEP 7. CREATE THE PROVIDER TABLE
-- Takes only 2 columns from STAGING
-- ============================================================

CREATE OR REPLACE TABLE PROVIDER (
    PROVIDER_ID   INT,
    PROVIDER_NAME VARCHAR
);

SELECT * FROM PROVIDER;


-- ============================================================
-- STEP 8. CREATE THE CLAIM TABLE
-- Takes the CLAIM_ID and the IDs of all the other tables,
-- plus the CLAIM_AMOUNT
-- ============================================================

CREATE OR REPLACE TABLE CLAIM (
    CLAIM_ID      INT,
    CUSTOMER_ID   INT,
    PRODUCT_ID    INT,
    LOCATION_ID   INT,
    PROVIDER_ID   INT,
    CLAIM_AMOUNT  NUMBER
);

SELECT * FROM CLAIM;


-- ============================================================
-- STEP 9. LOAD 1 - 5 RECORDS
-- After this: STAGING = 5 rows
-- ============================================================

INSERT INTO STAGING VALUES
(1, 'Rahul', 101, 'Laptop', 1, 'Bangalore', 201, 'Apollo Hospital', 1001, 5000),
(2, 'Amit', 102, 'Mobile', 2, 'Mumbai', 202, 'Fortis Hospital', 1002, 7000),
(3, 'Priya', 103, 'Tablet', 3, 'Pune', 203, 'Manipal Hospital', 1003, 4500),
(4, 'Sneha', 104, 'Monitor', 1, 'Bangalore', 204, 'Max Hospital', 1004, 6000),
(5, 'Rohit', 105, 'Keyboard', 4, 'Delhi', 205, 'Apollo Hospital', 1005, 3000);

SELECT COUNT(*) AS STAGING_ROWS FROM STAGING;


-- ============================================================
-- STEP 10. LOAD 2 - 5 RECORDS
-- After this: STAGING = 10 rows
-- ============================================================

INSERT INTO STAGING VALUES
(6, 'Karan', 106, 'Mouse', 5, 'Chennai', 206, 'Fortis Hospital', 1006, 2500),
(7, 'Neha', 107, 'Laptop', 6, 'Hyderabad', 207, 'Manipal Hospital', 1007, 8000),
(8, 'Akash', 108, 'Mobile', 7, 'Kolkata', 208, 'Max Hospital', 1008, 5500),
(9, 'Pooja', 109, 'Tablet', 8, 'Jaipur', 209, 'Apollo Hospital', 1009, 4000),
(10, 'Vikas', 110, 'Monitor', 9, 'Delhi', 210, 'Fortis Hospital', 1010, 6500);


-- ============================================================
-- STEP 11. LOAD 3 - 5 RECORDS
-- After this: STAGING = 15 rows
-- ============================================================

INSERT INTO STAGING VALUES
(11, 'Anjali', 111, 'Keyboard', 10, 'Mumbai', 211, 'Manipal Hospital', 1011, 2800),
(12, 'Suresh', 112, 'Mouse', 11, 'Pune', 212, 'Max Hospital', 1012, 2200),
(13, 'Meena', 113, 'Laptop', 12, 'Bangalore', 213, 'Apollo Hospital', 1013, 9000),
(14, 'Arjun', 114, 'Mobile', 13, 'Chennai', 214, 'Fortis Hospital', 1014, 7500),
(15, 'Nisha', 115, 'Tablet', 14, 'Hyderabad', 215, 'Manipal Hospital', 1015, 5000);


-- ============================================================
-- STEP 12. LOAD 4 - 5 RECORDS
-- After this: STAGING = 20 rows
-- ============================================================

INSERT INTO STAGING VALUES
(16, 'Manoj', 116, 'Monitor', 15, 'Kolkata', 216, 'Max Hospital', 1016, 6200),
(17, 'Divya', 117, 'Keyboard', 16, 'Jaipur', 217, 'Apollo Hospital', 1017, 3200),
(18, 'Ramesh', 118, 'Mouse', 17, 'Delhi', 218, 'Fortis Hospital', 1018, 2700),
(19, 'Kavya', 119, 'Laptop', 18, 'Mumbai', 219, 'Manipal Hospital', 1019, 9500),
(20, 'Ajay', 120, 'Mobile', 19, 'Pune', 220, 'Max Hospital', 1020, 6800);


-- ============================================================
-- STEP 13. LOAD 5 - 5 RECORDS
-- After this: STAGING = 25 rows
-- ============================================================

INSERT INTO STAGING VALUES
(21, 'Varun', 121, 'Tablet', 20, 'Bangalore', 221, 'Apollo Hospital', 1021, 4200),
(22, 'Swati', 122, 'Monitor', 21, 'Chennai', 222, 'Fortis Hospital', 1022, 5800),
(23, 'Naveen', 123, 'Keyboard', 22, 'Hyderabad', 223, 'Manipal Hospital', 1023, 3100),
(24, 'Riya', 124, 'Mouse', 23, 'Kolkata', 224, 'Max Hospital', 1024, 2400),
(25, 'Deepak', 125, 'Laptop', 24, 'Delhi', 225, 'Apollo Hospital', 1025, 8800);


-- ============================================================
-- STEP 14. LOAD 6 - 5 RECORDS
-- After this: STAGING = 30 rows
-- And all 5 target tables are still empty
-- ============================================================

INSERT INTO STAGING VALUES
(26, 'Pavan', 126, 'Mobile', 25, 'Mumbai', 226, 'Fortis Hospital', 1026, 7200),
(27, 'Asha', 127, 'Tablet', 26, 'Pune', 227, 'Manipal Hospital', 1027, 4600),
(28, 'Vijay', 128, 'Monitor', 27, 'Bangalore', 228, 'Max Hospital', 1028, 6100),
(29, 'Isha', 129, 'Keyboard', 28, 'Chennai', 229, 'Apollo Hospital', 1029, 2900),
(30, 'Sameer', 130, 'Mouse', 29, 'Hyderabad', 230, 'Fortis Hospital', 1030, 2600);

-- Shows all 30 rows in STAGING
SELECT * FROM STAGING ORDER BY CUSTOMER_ID;

SELECT COUNT(*) AS STAGING_ROWS FROM STAGING;

-- The 5 target tables are still empty
SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS FROM CLAIM;


-- ============================================================
-- STEP 15. SCENARIO 1 - WITHOUT A STORED PROCEDURE
-- We load the 5 tables by hand. That is 5 separate statements.
-- Each statement picks only the columns that its table needs.
--
-- This is the manual way. We must remember all 5 statements.
-- ============================================================

-- Load CUSTOMER
INSERT INTO CUSTOMER
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME
FROM STAGING;

-- Load PRODUCT
INSERT INTO PRODUCT
SELECT
    PRODUCT_ID,
    PRODUCT_NAME
FROM STAGING;

-- Load LOCATION
INSERT INTO LOCATION
SELECT
    LOCATION_ID,
    LOCATION_NAME
FROM STAGING;

-- Load PROVIDER
INSERT INTO PROVIDER
SELECT
    PROVIDER_ID,
    PROVIDER_NAME
FROM STAGING;

-- Load CLAIM
INSERT INTO CLAIM
SELECT
    CLAIM_ID,
    CUSTOMER_ID,
    PRODUCT_ID,
    LOCATION_ID,
    PROVIDER_ID,
    CLAIM_AMOUNT
FROM STAGING;

-- Now all 5 tables have 30 rows
SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS FROM CLAIM;


-- ============================================================
-- STEP 16. SCENARIO 2 - CREATE THE STORED PROCEDURE
-- We save all 5 statements inside ONE Stored Procedure.
-- After this, we never type those 5 statements again.
--
-- The SP does only this:
--   1. loads CUSTOMER
--   2. loads PRODUCT
--   3. loads LOCATION
--   4. loads PROVIDER
--   5. loads CLAIM
--   6. sends back a short message
--
-- No duplicate check. No error handling. On purpose. Keep it simple.
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_LOAD_DATA()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN

    -- Load CUSTOMER
    INSERT INTO CUSTOMER
    SELECT
        CUSTOMER_ID,
        CUSTOMER_NAME
    FROM STAGING;

    -- Load PRODUCT
    INSERT INTO PRODUCT
    SELECT
        PRODUCT_ID,
        PRODUCT_NAME
    FROM STAGING;

    -- Load LOCATION
    INSERT INTO LOCATION
    SELECT
        LOCATION_ID,
        LOCATION_NAME
    FROM STAGING;

    -- Load PROVIDER
    INSERT INTO PROVIDER
    SELECT
        PROVIDER_ID,
        PROVIDER_NAME
    FROM STAGING;

    -- Load CLAIM
    INSERT INTO CLAIM
    SELECT
        CLAIM_ID,
        CUSTOMER_ID,
        PRODUCT_ID,
        LOCATION_ID,
        PROVIDER_ID,
        CLAIM_AMOUNT
    FROM STAGING;

    RETURN 'DATA LOADED SUCCESSFULLY';

END;
$$;


-- ============================================================
-- STEP 17. RUN THE STORED PROCEDURE
-- No 5 statements. Just one short line.
-- The SP runs all 5 statements that are saved inside it.
--
-- ⚠️ This SP adds rows. Every CALL loads all rows again.
--    If you already ran Step 15, the 5 tables already have rows,
--    so this CALL adds the same rows a second time.
--    For this practice that is fine. We are learning the SP idea only.
-- ============================================================

CALL SP_LOAD_DATA();

SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS FROM CLAIM;


-- ============================================================
-- STEP 18. RUN THE SAME SP AGAIN (OPTIONAL)
-- This shows the important point:
-- 1st CALL -> each of the 5 tables gets 30 rows
-- 2nd CALL -> each of the 5 tables gets 60 rows
--             (the same rows added again)
--
-- For this practice that is fine. We are not doing duplicate checks yet.
--
-- 🚫 The CALL below is left switched off on purpose.
--    Why : it adds the same rows a second time and makes duplicates.
--    Uncomment it only when you want to see the 60 rows.
-- ============================================================

-- CALL SP_LOAD_DATA();


-- ============================================================
-- STEP 19. CHECK EVERYTHING
-- ============================================================

SELECT * FROM STAGING ORDER BY CUSTOMER_ID;

SELECT * FROM CUSTOMER ORDER BY CUSTOMER_ID;

SELECT * FROM PRODUCT ORDER BY PRODUCT_ID;

SELECT * FROM LOCATION ORDER BY LOCATION_ID;

SELECT * FROM PROVIDER ORDER BY PROVIDER_ID;

SELECT * FROM CLAIM ORDER BY CLAIM_ID;

SELECT COUNT(*) AS STAGING_ROWS FROM STAGING;
SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS FROM CLAIM;


-- ============================================================
-- STEP 20. SEE THE SP IN THE DATABASE
-- Lists the procedures in this schema
-- ============================================================

SHOW PROCEDURES;
