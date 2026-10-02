-- ============================================================
-- 60.1) Data Modelling - 05) SP + Audit - Staging to Multiple Tables
-- All the SQL for this practice, in one file.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- This is the next step after 04).
-- Two new things:
--   1. TWO audit tables, so we can see what happened
--   2. STAGING gets LOAD_ID + PROCESSED_FLAG, so the SP loads
--      only the NEW records and skips the old ones
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- The big box that holds everything for this practice
-- ============================================================

CREATE DATABASE IF NOT EXISTS SP_AUDIT_PRACTICE;

-- Uses this database for the next statements
USE DATABASE SP_AUDIT_PRACTICE;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- A folder that keeps this practice's tables together
-- ============================================================

CREATE SCHEMA IF NOT EXISTS SP_AUDIT_SCHEMA;

-- Uses this schema for the next statements
USE SCHEMA SP_AUDIT_SCHEMA;


-- ============================================================
-- STEP 3. CREATE THE STAGING TABLE
-- This is the MAIN source table.
-- Two new columns compared to the last practice:
--   LOAD_ID        -> which load this row belongs to
--   PROCESSED_FLAG -> 'N' = not loaded yet, 'Y' = already loaded
-- ============================================================

CREATE OR REPLACE TABLE STAGING (
    LOAD_ID        INT,
    CUSTOMER_ID    INT,
    CUSTOMER_NAME  VARCHAR,
    PRODUCT_ID     INT,
    PRODUCT_NAME   VARCHAR,
    LOCATION_ID    INT,
    LOCATION_NAME  VARCHAR,
    PROVIDER_ID    INT,
    PROVIDER_NAME  VARCHAR,
    CLAIM_ID       INT,
    CLAIM_AMOUNT   NUMBER,
    PROCESSED_FLAG VARCHAR
);

SELECT * FROM STAGING;


-- ============================================================
-- STEP 4. CREATE AUDIT TABLE 1 - STAGING_LOAD_AUDIT
-- Answers the question: WHAT CAME INTO STAGING?
-- One row is written here after every load
-- ============================================================

CREATE OR REPLACE TABLE STAGING_LOAD_AUDIT (
    LOAD_ID      INT,
    RECORD_COUNT INT,
    LOAD_TIME    TIMESTAMP,
    STATUS       VARCHAR,
    COMMENTS     VARCHAR
);

SELECT * FROM STAGING_LOAD_AUDIT;


-- ============================================================
-- STEP 5. CREATE AUDIT TABLE 2 - SP_LOAD_AUDIT
-- Answers the question: WHAT DID THE SP LOAD?
-- One row is written here for every LOAD_ID and TARGET_TABLE
-- ============================================================

CREATE OR REPLACE TABLE SP_LOAD_AUDIT (
    RUN_ID              INT,
    LOAD_ID             INT,
    SOURCE_TABLE        VARCHAR,
    TARGET_TABLE        VARCHAR,
    SOURCE_RECORD_COUNT INT,
    TARGET_RECORD_COUNT INT,
    RUN_TIME            TIMESTAMP,
    STATUS              VARCHAR,
    COMMENTS            VARCHAR
);

SELECT * FROM SP_LOAD_AUDIT;


-- ============================================================
-- STEP 6. CREATE THE CUSTOMER TABLE
-- ============================================================

CREATE OR REPLACE TABLE CUSTOMER (
    CUSTOMER_ID   INT,
    CUSTOMER_NAME VARCHAR
);

SELECT * FROM CUSTOMER;


-- ============================================================
-- STEP 7. CREATE THE PRODUCT TABLE
-- ============================================================

CREATE OR REPLACE TABLE PRODUCT (
    PRODUCT_ID   INT,
    PRODUCT_NAME VARCHAR
);

SELECT * FROM PRODUCT;


-- ============================================================
-- STEP 8. CREATE THE LOCATION TABLE
-- ============================================================

CREATE OR REPLACE TABLE LOCATION (
    LOCATION_ID   INT,
    LOCATION_NAME VARCHAR
);

SELECT * FROM LOCATION;


-- ============================================================
-- STEP 9. CREATE THE PROVIDER TABLE
-- ============================================================

CREATE OR REPLACE TABLE PROVIDER (
    PROVIDER_ID   INT,
    PROVIDER_NAME VARCHAR
);

SELECT * FROM PROVIDER;


-- ============================================================
-- STEP 10. CREATE THE CLAIM TABLE
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
-- STEP 11. LOAD 1 - 5 RECORDS
-- Every row carries LOAD_ID = 1 and PROCESSED_FLAG = 'N'
-- Then we write one row into STAGING_LOAD_AUDIT
-- ============================================================

INSERT INTO STAGING VALUES
(1, 1, 'Rahul', 101, 'Laptop', 1, 'Bangalore', 201, 'Apollo Hospital', 1001, 5000, 'N'),
(1, 2, 'Amit', 102, 'Mobile', 2, 'Mumbai', 202, 'Fortis Hospital', 1002, 7000, 'N'),
(1, 3, 'Priya', 103, 'Tablet', 3, 'Pune', 203, 'Manipal Hospital', 1003, 4500, 'N'),
(1, 4, 'Sneha', 104, 'Monitor', 1, 'Bangalore', 204, 'Max Hospital', 1004, 6000, 'N'),
(1, 5, 'Rohit', 105, 'Keyboard', 4, 'Delhi', 205, 'Apollo Hospital', 1005, 3000, 'N');

INSERT INTO STAGING_LOAD_AUDIT VALUES
(1, 5, CURRENT_TIMESTAMP(), 'SUCCESS', 'Load 1 inserted into STAGING');


-- ============================================================
-- STEP 12. LOAD 2 - 5 RECORDS
-- ============================================================

INSERT INTO STAGING VALUES
(2, 6, 'Karan', 106, 'Mouse', 5, 'Chennai', 206, 'Fortis Hospital', 1006, 2500, 'N'),
(2, 7, 'Neha', 107, 'Laptop', 6, 'Hyderabad', 207, 'Manipal Hospital', 1007, 8000, 'N'),
(2, 8, 'Akash', 108, 'Mobile', 7, 'Kolkata', 208, 'Max Hospital', 1008, 5500, 'N'),
(2, 9, 'Pooja', 109, 'Tablet', 8, 'Jaipur', 209, 'Apollo Hospital', 1009, 4000, 'N'),
(2, 10, 'Vikas', 110, 'Monitor', 9, 'Delhi', 210, 'Fortis Hospital', 1010, 6500, 'N');

INSERT INTO STAGING_LOAD_AUDIT VALUES
(2, 5, CURRENT_TIMESTAMP(), 'SUCCESS', 'Load 2 inserted into STAGING');


-- ============================================================
-- STEP 13. LOAD 3 - 5 RECORDS
-- ============================================================

INSERT INTO STAGING VALUES
(3, 11, 'Anjali', 111, 'Keyboard', 10, 'Mumbai', 211, 'Manipal Hospital', 1011, 2800, 'N'),
(3, 12, 'Suresh', 112, 'Mouse', 11, 'Pune', 212, 'Max Hospital', 1012, 2200, 'N'),
(3, 13, 'Meena', 113, 'Laptop', 12, 'Bangalore', 213, 'Apollo Hospital', 1013, 9000, 'N'),
(3, 14, 'Arjun', 114, 'Mobile', 13, 'Chennai', 214, 'Fortis Hospital', 1014, 7500, 'N'),
(3, 15, 'Nisha', 115, 'Tablet', 14, 'Hyderabad', 215, 'Manipal Hospital', 1015, 5000, 'N');

INSERT INTO STAGING_LOAD_AUDIT VALUES
(3, 5, CURRENT_TIMESTAMP(), 'SUCCESS', 'Load 3 inserted into STAGING');


-- ============================================================
-- STEP 14. LOAD 4 - 5 RECORDS
-- ============================================================

INSERT INTO STAGING VALUES
(4, 16, 'Manoj', 116, 'Monitor', 15, 'Kolkata', 216, 'Max Hospital', 1016, 6200, 'N'),
(4, 17, 'Divya', 117, 'Keyboard', 16, 'Jaipur', 217, 'Apollo Hospital', 1017, 3200, 'N'),
(4, 18, 'Ramesh', 118, 'Mouse', 17, 'Delhi', 218, 'Fortis Hospital', 1018, 2700, 'N'),
(4, 19, 'Kavya', 119, 'Laptop', 18, 'Mumbai', 219, 'Manipal Hospital', 1019, 9500, 'N'),
(4, 20, 'Ajay', 120, 'Mobile', 19, 'Pune', 220, 'Max Hospital', 1020, 6800, 'N');

INSERT INTO STAGING_LOAD_AUDIT VALUES
(4, 5, CURRENT_TIMESTAMP(), 'SUCCESS', 'Load 4 inserted into STAGING');


-- ============================================================
-- STEP 15. LOAD 5 - 5 RECORDS
-- ============================================================

INSERT INTO STAGING VALUES
(5, 21, 'Varun', 121, 'Tablet', 20, 'Bangalore', 221, 'Apollo Hospital', 1021, 4200, 'N'),
(5, 22, 'Swati', 122, 'Monitor', 21, 'Chennai', 222, 'Fortis Hospital', 1022, 5800, 'N'),
(5, 23, 'Naveen', 123, 'Keyboard', 22, 'Hyderabad', 223, 'Manipal Hospital', 1023, 3100, 'N'),
(5, 24, 'Riya', 124, 'Mouse', 23, 'Kolkata', 224, 'Max Hospital', 1024, 2400, 'N'),
(5, 25, 'Deepak', 125, 'Laptop', 24, 'Delhi', 225, 'Apollo Hospital', 1025, 8800, 'N');

INSERT INTO STAGING_LOAD_AUDIT VALUES
(5, 5, CURRENT_TIMESTAMP(), 'SUCCESS', 'Load 5 inserted into STAGING');


-- ============================================================
-- STEP 16. LOAD 6 - 5 RECORDS
-- After this: STAGING = 30 rows, all PROCESSED_FLAG = 'N'
-- ============================================================

INSERT INTO STAGING VALUES
(6, 26, 'Pavan', 126, 'Mobile', 25, 'Mumbai', 226, 'Fortis Hospital', 1026, 7200, 'N'),
(6, 27, 'Asha', 127, 'Tablet', 26, 'Pune', 227, 'Manipal Hospital', 1027, 4600, 'N'),
(6, 28, 'Vijay', 128, 'Monitor', 27, 'Bangalore', 228, 'Max Hospital', 1028, 6100, 'N'),
(6, 29, 'Isha', 129, 'Keyboard', 28, 'Chennai', 229, 'Apollo Hospital', 1029, 2900, 'N'),
(6, 30, 'Sameer', 130, 'Mouse', 29, 'Hyderabad', 230, 'Fortis Hospital', 1030, 2600, 'N');

INSERT INTO STAGING_LOAD_AUDIT VALUES
(6, 5, CURRENT_TIMESTAMP(), 'SUCCESS', 'Load 6 inserted into STAGING');


-- ============================================================
-- STEP 17. CHECK: WHAT IS WAITING?
-- STAGING should have 30 rows, all with PROCESSED_FLAG = 'N'
-- The 5 target tables should all be empty
-- ============================================================

SELECT * FROM STAGING ORDER BY LOAD_ID, CUSTOMER_ID;

SELECT PROCESSED_FLAG, COUNT(*) AS ROWS_WAITING
FROM STAGING
GROUP BY PROCESSED_FLAG;

SELECT * FROM STAGING_LOAD_AUDIT ORDER BY LOAD_ID;

SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS  FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS    FROM CLAIM;


-- ============================================================
-- STEP 18. CREATE THE STORED PROCEDURE
-- This SP is smarter than the one in 04).
-- It does 5 things, in this order:
--
--   1. counts the rows waiting (PROCESSED_FLAG = 'N')
--   2. loads only those rows into the 5 target tables
--   3. writes the audit rows into SP_LOAD_AUDIT
--   4. marks those rows as processed (PROCESSED_FLAG = 'Y')
--   5. returns a short message
--
-- NOTE on the audit counts:
--   In this practice every STAGING row becomes one row in each
--   target table. So the source count and the target count are
--   the same number. We still keep both columns, because in a
--   real project the two numbers can be different.
--
-- No transactions and no error handling yet. On purpose. Keep it simple.
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_LOAD_DATA()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    RUN_ID_VAR INT;
    SRC_COUNT  INT;
BEGIN

    -- --------------------------------------------------------
    -- 1. How many rows are waiting?
    -- --------------------------------------------------------
    SELECT COUNT(*) INTO :SRC_COUNT
    FROM STAGING
    WHERE PROCESSED_FLAG = 'N';

    IF (:SRC_COUNT = 0) THEN
        RETURN 'NO NEW RECORDS TO LOAD';
    END IF;

    -- --------------------------------------------------------
    -- 2. Get the next RUN_ID for the audit table
    -- --------------------------------------------------------
    SELECT COALESCE(MAX(RUN_ID), 0) + 1 INTO :RUN_ID_VAR
    FROM SP_LOAD_AUDIT;

    -- --------------------------------------------------------
    -- 3. Load the 5 target tables
    -- Only the rows that are not processed yet
    -- --------------------------------------------------------

    INSERT INTO CUSTOMER (CUSTOMER_ID, CUSTOMER_NAME)
    SELECT CUSTOMER_ID, CUSTOMER_NAME
    FROM STAGING
    WHERE PROCESSED_FLAG = 'N';

    INSERT INTO PRODUCT (PRODUCT_ID, PRODUCT_NAME)
    SELECT PRODUCT_ID, PRODUCT_NAME
    FROM STAGING
    WHERE PROCESSED_FLAG = 'N';

    INSERT INTO LOCATION (LOCATION_ID, LOCATION_NAME)
    SELECT LOCATION_ID, LOCATION_NAME
    FROM STAGING
    WHERE PROCESSED_FLAG = 'N';

    INSERT INTO PROVIDER (PROVIDER_ID, PROVIDER_NAME)
    SELECT PROVIDER_ID, PROVIDER_NAME
    FROM STAGING
    WHERE PROCESSED_FLAG = 'N';

    INSERT INTO CLAIM (CLAIM_ID, CUSTOMER_ID, PRODUCT_ID, LOCATION_ID, PROVIDER_ID, CLAIM_AMOUNT)
    SELECT CLAIM_ID, CUSTOMER_ID, PRODUCT_ID, LOCATION_ID, PROVIDER_ID, CLAIM_AMOUNT
    FROM STAGING
    WHERE PROCESSED_FLAG = 'N';

    -- --------------------------------------------------------
    -- 4. Write the audit rows
    -- One row for every LOAD_ID and every TARGET_TABLE
    -- All 5 target tables get the same rows, so we build the
    -- target list once and combine it with the load counts
    -- --------------------------------------------------------
    INSERT INTO SP_LOAD_AUDIT
        (RUN_ID, LOAD_ID, SOURCE_TABLE, TARGET_TABLE,
         SOURCE_RECORD_COUNT, TARGET_RECORD_COUNT,
         RUN_TIME, STATUS, COMMENTS)
    SELECT
        :RUN_ID_VAR,
        S.LOAD_ID,
        'STAGING',
        T.TARGET_TABLE,
        S.CNT,
        S.CNT,
        CURRENT_TIMESTAMP(),
        'SUCCESS',
        'STAGING -> ' || T.TARGET_TABLE
    FROM (
        SELECT LOAD_ID, COUNT(*) AS CNT
        FROM STAGING
        WHERE PROCESSED_FLAG = 'N'
        GROUP BY LOAD_ID
    ) S
    CROSS JOIN (
        SELECT 'CUSTOMER' AS TARGET_TABLE
        UNION ALL SELECT 'PRODUCT'
        UNION ALL SELECT 'LOCATION'
        UNION ALL SELECT 'PROVIDER'
        UNION ALL SELECT 'CLAIM'
    ) T;

    -- --------------------------------------------------------
    -- 5. Mark the loaded rows as processed
    -- This must come LAST, because steps 3 and 4 read the 'N' rows
    -- --------------------------------------------------------
    UPDATE STAGING
    SET PROCESSED_FLAG = 'Y'
    WHERE PROCESSED_FLAG = 'N';

    RETURN 'DATA LOADED SUCCESSFULLY';

END;
$$;


-- ============================================================
-- STEP 19. RUN THE STORED PROCEDURE
-- One short line. The SP loads only the 'N' rows.
-- After this: the 5 target tables have 30 rows each,
--             and all 30 STAGING rows are marked 'Y'
-- ============================================================

CALL SP_LOAD_DATA();

SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS  FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS    FROM CLAIM;


-- ============================================================
-- STEP 20. CHECK WHAT THE SP DID
-- Look at SP_LOAD_AUDIT: one row per LOAD_ID and per target table
-- ============================================================

SELECT * FROM SP_LOAD_AUDIT ORDER BY LOAD_ID, TARGET_TABLE;

-- How many rows are still waiting? This should be 0
SELECT PROCESSED_FLAG, COUNT(*) AS ROWS_WAITING
FROM STAGING
GROUP BY PROCESSED_FLAG;


-- ============================================================
-- STEP 21. RUN THE SAME SP AGAIN
-- This is the big improvement over 04).
-- Nothing is waiting now, so nothing is loaded again.
-- The SP returns 'NO NEW RECORDS TO LOAD'.
-- The target tables stay at 30 rows. No duplicates. ✅
-- ============================================================

CALL SP_LOAD_DATA();

SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS  FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS    FROM CLAIM;


-- ============================================================
-- STEP 22. A NEW LOAD ARRIVES - LOAD 7 (5 NEW RECORDS)
-- The document only says "suppose Load 7 arrives".
-- We add 5 simple records here, so you can really see that
-- only the new records are loaded.
-- These 5 rows start with PROCESSED_FLAG = 'N'
-- ============================================================

INSERT INTO STAGING VALUES
(7, 31, 'Rakesh', 131, 'Printer', 30, 'Noida', 231, 'AIIMS', 1031, 5200, 'N'),
(7, 32, 'Pooja', 132, 'Scanner', 31, 'Surat', 232, 'Ruby Hall', 1032, 4800, 'N'),
(7, 33, 'Imran', 133, 'Speaker', 32, 'Indore', 233, 'Care Hospital', 1033, 3700, 'N'),
(7, 34, 'Sonal', 134, 'Router', 33, 'Nagpur', 234, 'KIMS', 1034, 8100, 'N'),
(7, 35, 'Tarun', 135, 'Webcam', 34, 'Bhopal', 235, 'Medanta', 1035, 5900, 'N');

INSERT INTO STAGING_LOAD_AUDIT VALUES
(7, 5, CURRENT_TIMESTAMP(), 'SUCCESS', 'Load 7 inserted into STAGING');

-- STAGING now has 35 rows: 30 x 'Y' and 5 x 'N'
SELECT PROCESSED_FLAG, COUNT(*) AS ROWS
FROM STAGING
GROUP BY PROCESSED_FLAG
ORDER BY PROCESSED_FLAG;


-- ============================================================
-- STEP 23. RUN THE SP ONE MORE TIME
-- The SP should pick up ONLY the 5 new rows (LOAD_ID = 7).
-- The old 30 rows are skipped, because their flag is 'Y'.
--
-- After this: the 5 target tables have 35 rows each,
--             not 65. That is the improvement. ✅
-- ============================================================

CALL SP_LOAD_DATA();

SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS  FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS    FROM CLAIM;

-- Only the new load appears in the audit
SELECT * FROM SP_LOAD_AUDIT ORDER BY RUN_ID, LOAD_ID, TARGET_TABLE;


-- ============================================================
-- STEP 24. CHECK EVERYTHING
-- ============================================================

SELECT * FROM STAGING ORDER BY LOAD_ID, CUSTOMER_ID;

SELECT PROCESSED_FLAG, COUNT(*) AS ROWS
FROM STAGING
GROUP BY PROCESSED_FLAG;

SELECT * FROM STAGING_LOAD_AUDIT ORDER BY LOAD_ID;

SELECT * FROM CUSTOMER ORDER BY CUSTOMER_ID;
SELECT * FROM PRODUCT  ORDER BY PRODUCT_ID;
SELECT * FROM LOCATION ORDER BY LOCATION_ID;
SELECT * FROM PROVIDER ORDER BY PROVIDER_ID;
SELECT * FROM CLAIM    ORDER BY CLAIM_ID;

SELECT COUNT(*) AS STAGING_ROWS  FROM STAGING;
SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS  FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS    FROM CLAIM;


-- ============================================================
-- STEP 25. SEE THE SP IN THE DATABASE
-- ============================================================

SHOW PROCEDURES;
