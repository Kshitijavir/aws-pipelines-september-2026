-- ============================================================
-- 60.1) Data Modelling - 06) SP Task-Based Data Load
-- All the SQL for this practice, in one file.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- This is the next step after 05).
-- New thing: a SNOWFLAKE TASK checks every 1 minute.
-- It waits until nothing new arrives for 3 checks in a row,
-- and only then calls SP_LOAD_DATA().
--
-- So we no longer call the SP by hand.
--
-- NOTE: a Task needs compute, so this practice creates its
--       own small warehouse: TASK_LOAD_WH
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- ============================================================

CREATE DATABASE IF NOT EXISTS SP_TASK_PRACTICE;

USE DATABASE SP_TASK_PRACTICE;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS SP_TASK_SCHEMA;

USE SCHEMA SP_TASK_SCHEMA;


-- ============================================================
-- STEP 3. CREATE THE WAREHOUSE
-- A Task needs compute to run, so we create one small warehouse
-- AUTO_SUSPEND = 60 means it stops by itself after 60 seconds
-- of no use, so it does not keep costing money
-- ============================================================

CREATE WAREHOUSE IF NOT EXISTS TASK_LOAD_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE TASK_LOAD_WH;


-- ============================================================
-- STEP 4. CREATE THE STAGING TABLE
-- Same idea as the last practice: LOAD_ID + PROCESSED_FLAG
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
-- STEP 5. CREATE AUDIT TABLE 1 - STAGING_LOAD_AUDIT
-- Answers: WHAT CAME INTO STAGING?
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
-- STEP 6. CREATE AUDIT TABLE 2 - SP_LOAD_AUDIT
-- Answers: WHAT DID THE SP LOAD?
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
-- STEP 7. CREATE AUDIT TABLE 3 - TASK_CHECK_AUDIT (NEW)
-- Answers: WHAT DID THE TASK CHECK, AND WHY DID IT CALL THE SP?
-- One row is written here on every single check
-- ============================================================

CREATE OR REPLACE TABLE TASK_CHECK_AUDIT (
    CHECK_ID                   INT,
    CHECK_TIME                 TIMESTAMP,
    RECORD_COUNT               INT,
    NEW_RECORD_FOUND           VARCHAR,
    CONSECUTIVE_NO_DATA_COUNT  INT,
    ACTION                     VARCHAR,
    COMMENTS                   VARCHAR
);

SELECT * FROM TASK_CHECK_AUDIT;


-- ============================================================
-- STEP 8. CREATE THE CUSTOMER TABLE
-- ============================================================

CREATE OR REPLACE TABLE CUSTOMER (
    CUSTOMER_ID   INT,
    CUSTOMER_NAME VARCHAR
);

SELECT * FROM CUSTOMER;


-- ============================================================
-- STEP 9. CREATE THE PRODUCT TABLE
-- ============================================================

CREATE OR REPLACE TABLE PRODUCT (
    PRODUCT_ID   INT,
    PRODUCT_NAME VARCHAR
);

SELECT * FROM PRODUCT;


-- ============================================================
-- STEP 10. CREATE THE LOCATION TABLE
-- ============================================================

CREATE OR REPLACE TABLE LOCATION (
    LOCATION_ID   INT,
    LOCATION_NAME VARCHAR
);

SELECT * FROM LOCATION;


-- ============================================================
-- STEP 11. CREATE THE PROVIDER TABLE
-- ============================================================

CREATE OR REPLACE TABLE PROVIDER (
    PROVIDER_ID   INT,
    PROVIDER_NAME VARCHAR
);

SELECT * FROM PROVIDER;


-- ============================================================
-- STEP 12. CREATE THE CLAIM TABLE
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
-- STEP 13. CREATE THE LOAD PROCEDURE (the same idea as 05)
-- It loads ONLY the rows where PROCESSED_FLAG = 'N',
-- writes the audit rows, then marks those rows as 'Y'
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

    -- 1. How many rows are waiting?
    SELECT COUNT(*) INTO :SRC_COUNT
    FROM STAGING
    WHERE PROCESSED_FLAG = 'N';

    IF (:SRC_COUNT = 0) THEN
        RETURN 'NO NEW RECORDS TO LOAD';
    END IF;

    -- 2. Next RUN_ID for the audit table
    SELECT COALESCE(MAX(RUN_ID), 0) + 1 INTO :RUN_ID_VAR
    FROM SP_LOAD_AUDIT;

    -- 3. Load the 5 target tables (only the rows not processed yet)
    INSERT INTO CUSTOMER (CUSTOMER_ID, CUSTOMER_NAME)
    SELECT CUSTOMER_ID, CUSTOMER_NAME
    FROM STAGING WHERE PROCESSED_FLAG = 'N';

    INSERT INTO PRODUCT (PRODUCT_ID, PRODUCT_NAME)
    SELECT PRODUCT_ID, PRODUCT_NAME
    FROM STAGING WHERE PROCESSED_FLAG = 'N';

    INSERT INTO LOCATION (LOCATION_ID, LOCATION_NAME)
    SELECT LOCATION_ID, LOCATION_NAME
    FROM STAGING WHERE PROCESSED_FLAG = 'N';

    INSERT INTO PROVIDER (PROVIDER_ID, PROVIDER_NAME)
    SELECT PROVIDER_ID, PROVIDER_NAME
    FROM STAGING WHERE PROCESSED_FLAG = 'N';

    INSERT INTO CLAIM (CLAIM_ID, CUSTOMER_ID, PRODUCT_ID, LOCATION_ID, PROVIDER_ID, CLAIM_AMOUNT)
    SELECT CLAIM_ID, CUSTOMER_ID, PRODUCT_ID, LOCATION_ID, PROVIDER_ID, CLAIM_AMOUNT
    FROM STAGING WHERE PROCESSED_FLAG = 'N';

    -- 4. Write the audit rows: one row per LOAD_ID and per target table
    -- In this practice every STAGING row becomes one row in each target
    -- table, so the source count and the target count are the same number
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

    -- 5. Mark the loaded rows as processed. This must come LAST.
    UPDATE STAGING
    SET PROCESSED_FLAG = 'Y'
    WHERE PROCESSED_FLAG = 'N';

    RETURN 'DATA LOADED SUCCESSFULLY';

END;
$$;


-- ============================================================
-- STEP 14. CREATE THE CHECK PROCEDURE (NEW)
-- This is the procedure the Task will call every 1 minute.
-- It does this:
--
--   1. counts the rows waiting (PROCESSED_FLAG = 'N')
--   2. compares that count with the previous check
--   3. if the count went UP  -> new records came -> counter = 0
--      if the count stayed   -> nothing new       -> counter + 1
--   4. writes one row into TASK_CHECK_AUDIT
--   5. if the counter reaches 3 -> CALL SP_LOAD_DATA()
--
-- So the Task does the waiting. The SP runs only once, at the end.
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_TASK_CHECK()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    CHECK_ID_VAR  INT;
    CUR_COUNT     INT;
    AUDIT_ROWS    INT;
    PREV_COUNT    INT;
    PREV_NO_DATA  INT;
    NEW_FOUND     VARCHAR;
    NO_DATA_COUNT INT;
    ACTION_VAR    VARCHAR;
BEGIN

    -- 1. The next CHECK_ID
    SELECT COALESCE(MAX(CHECK_ID), 0) + 1 INTO :CHECK_ID_VAR
    FROM TASK_CHECK_AUDIT;

    -- 2. How many rows are still waiting?
    SELECT COUNT(*) INTO :CUR_COUNT
    FROM STAGING
    WHERE PROCESSED_FLAG = 'N';

    -- 3. Read the previous check row, if there is one
    SELECT COUNT(*) INTO :AUDIT_ROWS FROM TASK_CHECK_AUDIT;

    PREV_COUNT   := 0;
    PREV_NO_DATA := 0;

    IF (:AUDIT_ROWS > 0) THEN
        SELECT RECORD_COUNT, CONSECUTIVE_NO_DATA_COUNT
          INTO :PREV_COUNT, :PREV_NO_DATA
        FROM TASK_CHECK_AUDIT
        WHERE CHECK_ID = (SELECT MAX(CHECK_ID) FROM TASK_CHECK_AUDIT);
    END IF;

    -- 4. Decide what this check means
    IF (:CUR_COUNT = 0) THEN
        -- Nothing is waiting at all, so stay idle
        NEW_FOUND     := 'N';
        NO_DATA_COUNT := 0;
        ACTION_VAR    := 'IDLE';

    ELSEIF (:AUDIT_ROWS = 0) THEN
        -- This is the very first check. Start counting.
        NEW_FOUND     := 'N';
        NO_DATA_COUNT := 1;
        ACTION_VAR    := 'WAIT';

    ELSEIF (:CUR_COUNT = :PREV_COUNT) THEN
        -- Nothing new since the last check
        NEW_FOUND     := 'N';
        NO_DATA_COUNT := :PREV_NO_DATA + 1;

        IF (:NO_DATA_COUNT >= 3) THEN
            ACTION_VAR := 'CALL SP';
        ELSE
            ACTION_VAR := 'WAIT';
        END IF;

    ELSE
        -- New records came in, so start counting again
        NEW_FOUND     := 'Y';
        NO_DATA_COUNT := 0;
        ACTION_VAR    := 'WAIT';
    END IF;

    -- 5. Write this check into the audit table
    INSERT INTO TASK_CHECK_AUDIT
        (CHECK_ID, CHECK_TIME, RECORD_COUNT, NEW_RECORD_FOUND,
         CONSECUTIVE_NO_DATA_COUNT, ACTION, COMMENTS)
    VALUES
        (:CHECK_ID_VAR, CURRENT_TIMESTAMP(), :CUR_COUNT, :NEW_FOUND,
         :NO_DATA_COUNT, :ACTION_VAR, 'task check');

    -- 6. If the data has been quiet for 3 checks, load it now
    IF (:ACTION_VAR = 'CALL SP') THEN
        CALL SP_LOAD_DATA();
        RETURN 'ACTION = CALL SP';
    END IF;

    RETURN 'ACTION = ' || :ACTION_VAR;

END;
$$;


-- ============================================================
-- STEP 15. CREATE THE TASK
-- The Task wakes up every 1 minute and calls the check procedure.
--
-- ⚠️ A new Task is created SUSPENDED. It does not run yet.
--    To start the real 1-minute schedule, run: ALTER TASK ... RESUME
--    (see Step 32 at the end of this file)
-- ============================================================

CREATE OR REPLACE TASK TASK_LOAD_DATA
    WAREHOUSE = TASK_LOAD_WH
    SCHEDULE = '1 MINUTE'
AS
    CALL SP_TASK_CHECK();

-- Shows the task and its state (it should say "suspended")
SHOW TASKS;


-- ============================================================
-- STEP 16. LOAD 1 - 5 RECORDS
-- Every row carries LOAD_ID = 1 and PROCESSED_FLAG = 'N'
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
-- STEP 17. LOAD 2 - 5 RECORDS
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
-- STEP 18. LOAD 3 - 5 RECORDS
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
-- STEP 19. LOAD 4 - 5 RECORDS
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
-- STEP 20. LOAD 5 - 5 RECORDS
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
-- STEP 21. LOAD 6 - 5 RECORDS
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
-- STEP 22. CHECK: WHAT IS WAITING?
-- 30 rows should be waiting, and the 5 target tables should be empty
-- ============================================================

SELECT PROCESSED_FLAG, COUNT(*) AS ROWS_WAITING
FROM STAGING
GROUP BY PROCESSED_FLAG;

SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS  FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS    FROM CLAIM;


-- ============================================================
-- STEP 23. RUN THE CHECK - CHECK 1
-- The Task would do this by itself every 1 minute.
-- For this practice we run it by hand so we do not have to wait.
--
-- Expected: no new data since the start, count = 1, action = WAIT
-- ============================================================

CALL SP_TASK_CHECK();

SELECT * FROM TASK_CHECK_AUDIT ORDER BY CHECK_ID;


-- ============================================================
-- STEP 24. RUN THE CHECK - CHECK 2
-- Expected: still nothing new, count = 2, action = WAIT
-- ============================================================

CALL SP_TASK_CHECK();

SELECT * FROM TASK_CHECK_AUDIT ORDER BY CHECK_ID;


-- ============================================================
-- STEP 25. RUN THE CHECK - CHECK 3
-- Expected: nothing new again, count = 3
--           -> action = CALL SP
--           -> the SP runs and loads the 30 records
-- ============================================================

CALL SP_TASK_CHECK();

SELECT * FROM TASK_CHECK_AUDIT ORDER BY CHECK_ID;


-- ============================================================
-- STEP 26. CHECK WHAT HAPPENED
-- The 5 target tables should now have 30 rows each,
-- and all 30 STAGING rows should be marked 'Y'
-- ============================================================

SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS  FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS    FROM CLAIM;

SELECT PROCESSED_FLAG, COUNT(*) AS ROWS
FROM STAGING
GROUP BY PROCESSED_FLAG;

SELECT * FROM SP_LOAD_AUDIT ORDER BY LOAD_ID, TARGET_TABLE;


-- ============================================================
-- STEP 27. A NEW LOAD ARRIVES LATER - LOAD 7 (5 NEW RECORDS)
-- The document only says "suppose another load comes later".
-- We add 5 simple records here so you can see it work.
-- ============================================================

INSERT INTO STAGING VALUES
(7, 31, 'Rakesh', 131, 'Printer', 30, 'Noida', 231, 'AIIMS', 1031, 5200, 'N'),
(7, 32, 'Pooja', 132, 'Scanner', 31, 'Surat', 232, 'Ruby Hall', 1032, 4800, 'N'),
(7, 33, 'Imran', 133, 'Speaker', 32, 'Indore', 233, 'Care Hospital', 1033, 3700, 'N'),
(7, 34, 'Sonal', 134, 'Router', 33, 'Nagpur', 234, 'KIMS', 1034, 8100, 'N'),
(7, 35, 'Tarun', 135, 'Webcam', 34, 'Bhopal', 235, 'Medanta', 1035, 5900, 'N');

INSERT INTO STAGING_LOAD_AUDIT VALUES
(7, 5, CURRENT_TIMESTAMP(), 'SUCCESS', 'Load 7 inserted into STAGING');

-- 30 rows are 'Y' and 5 rows are 'N'
SELECT PROCESSED_FLAG, COUNT(*) AS ROWS
FROM STAGING
GROUP BY PROCESSED_FLAG
ORDER BY PROCESSED_FLAG;


-- ============================================================
-- STEP 28. RUN THE CHECK - CHECK 4
-- New records came in, so the counter goes back to 0
-- Expected: new data found = Y, count = 0, action = WAIT
-- ============================================================

CALL SP_TASK_CHECK();

SELECT * FROM TASK_CHECK_AUDIT ORDER BY CHECK_ID;


-- ============================================================
-- STEP 29. RUN THE CHECK - CHECK 5
-- Expected: nothing new, count = 1, action = WAIT
-- ============================================================

CALL SP_TASK_CHECK();

SELECT * FROM TASK_CHECK_AUDIT ORDER BY CHECK_ID;


-- ============================================================
-- STEP 30. RUN THE CHECK - CHECK 6
-- Expected: nothing new, count = 2, action = WAIT
-- ============================================================

CALL SP_TASK_CHECK();

SELECT * FROM TASK_CHECK_AUDIT ORDER BY CHECK_ID;


-- ============================================================
-- STEP 31. RUN THE CHECK - CHECK 7
-- Expected: nothing new, count = 3 -> action = CALL SP
-- The SP should load ONLY the 5 new rows.
--
-- After this the 5 target tables should have 35 rows each, not 60.
-- The old 30 rows are skipped because their flag is 'Y'. ✅
-- ============================================================

CALL SP_TASK_CHECK();

SELECT * FROM TASK_CHECK_AUDIT ORDER BY CHECK_ID;

SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS  FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS    FROM CLAIM;

SELECT * FROM SP_LOAD_AUDIT ORDER BY RUN_ID, LOAD_ID, TARGET_TABLE;


-- ============================================================
-- STEP 32. TURN ON THE REAL 1-MINUTE SCHEDULE (OPTIONAL)
-- A new Task is suspended. This line makes it really run
-- every 1 minute, on its own, without us calling anything.
--
-- ⚠️ While this is running, the Task keeps checking every minute,
--    so it keeps adding rows into TASK_CHECK_AUDIT and keeps
--    using the warehouse. Remember Step 33 to stop it.
-- ============================================================

-- ALTER TASK TASK_LOAD_DATA RESUME;


-- ============================================================
-- STEP 33. STOP THE TASK (and stop the cost)
-- Run this when you are done so the Task stops checking.
-- ============================================================

ALTER TASK IF EXISTS TASK_LOAD_DATA SUSPEND;

ALTER WAREHOUSE IF EXISTS TASK_LOAD_WH SUSPEND;

SHOW TASKS;


-- ============================================================
-- STEP 34. SEE THE TASK HISTORY
-- Shows every run of the Task, its state and any error
-- ============================================================

SELECT
    NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME => 'TASK_LOAD_DATA'))
ORDER BY SCHEDULED_TIME DESC
LIMIT 20;


-- ============================================================
-- STEP 35. CHECK EVERYTHING ONE LAST TIME
-- ============================================================

SELECT * FROM STAGING ORDER BY LOAD_ID, CUSTOMER_ID;

SELECT * FROM STAGING_LOAD_AUDIT ORDER BY LOAD_ID;

SELECT * FROM TASK_CHECK_AUDIT ORDER BY CHECK_ID;

SELECT * FROM SP_LOAD_AUDIT ORDER BY RUN_ID, LOAD_ID, TARGET_TABLE;

SELECT COUNT(*) AS STAGING_ROWS  FROM STAGING;
SELECT COUNT(*) AS CUSTOMER_ROWS FROM CUSTOMER;
SELECT COUNT(*) AS PRODUCT_ROWS  FROM PRODUCT;
SELECT COUNT(*) AS LOCATION_ROWS FROM LOCATION;
SELECT COUNT(*) AS PROVIDER_ROWS FROM PROVIDER;
SELECT COUNT(*) AS CLAIM_ROWS    FROM CLAIM;

SHOW PROCEDURES;
