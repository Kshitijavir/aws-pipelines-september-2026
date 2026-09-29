-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

CREATE DATABASE SNOWFLAKE_TASK_PRACTICE;

-- Use this database from now on
USE DATABASE SNOWFLAKE_TASK_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- ============================================================

CREATE SCHEMA TASK_SCHEMA;

-- Use this schema from now on
USE SCHEMA TASK_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- ============================================================

CREATE WAREHOUSE TASK_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Use this warehouse
USE WAREHOUSE TASK_WH;


-- ============================================================
-- 4. CREATE THE FOUR EMPLOYEE TABLES
-- ============================================================

CREATE TABLE EMPLOYEE_DATA_1 (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

-- Check the empty table
SELECT * FROM EMPLOYEE_DATA_1;


CREATE TABLE EMPLOYEE_DATA_2 (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

-- Check the empty table
SELECT * FROM EMPLOYEE_DATA_2;


CREATE TABLE EMPLOYEE_DATA_3 (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

-- Check the empty table
SELECT * FROM EMPLOYEE_DATA_3;


CREATE TABLE EMPLOYEE_DATA_4 (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

-- Check the empty table
SELECT * FROM EMPLOYEE_DATA_4;


-- ============================================================
-- 5. INSERT DATA INTO THE FOUR TABLES
-- Every table gets its own five records
-- ============================================================

INSERT INTO EMPLOYEE_DATA_1 VALUES
(1001, 'Rahul', 'IT', 85000),
(1002, 'Priya', 'HR', 65000),
(1003, 'Amit', 'Finance', 95000),
(1004, 'Sneha', 'IT', 78000),
(1005, 'Vikas', 'Sales', 55000);

-- Verify inserted records
SELECT * FROM EMPLOYEE_DATA_1;


INSERT INTO EMPLOYEE_DATA_2 VALUES
(2001, 'Rohit', 'IT', 72000),
(2002, 'Kavita', 'HR', 61000),
(2003, 'Manoj', 'Finance', 88000),
(2004, 'Pooja', 'IT', 69000),
(2005, 'Suresh', 'Sales', 52000);

-- Verify inserted records
SELECT * FROM EMPLOYEE_DATA_2;


INSERT INTO EMPLOYEE_DATA_3 VALUES
(3001, 'Arjun', 'IT', 91000),
(3002, 'Neha', 'HR', 67000),
(3003, 'Ravi', 'Finance', 83000),
(3004, 'Meera', 'IT', 76000),
(3005, 'Karan', 'Sales', 59000);

-- Verify inserted records
SELECT * FROM EMPLOYEE_DATA_3;


INSERT INTO EMPLOYEE_DATA_4 VALUES
(4001, 'Deepak', 'IT', 81000),
(4002, 'Anita', 'HR', 64000),
(4003, 'Sunil', 'Finance', 99000),
(4004, 'Ritu', 'IT', 70000),
(4005, 'Anil', 'Sales', 54000);

-- Verify inserted records
SELECT * FROM EMPLOYEE_DATA_4;


-- ============================================================
-- 6. CREATE THE FOUR CSV FILE FORMATS
-- One format for each stage, so every export is configured once
-- ============================================================

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_1
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_2
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_3
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_4
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';


-- ============================================================
-- 7. CREATE THE FOUR INTERNAL STAGES
-- Stage 1 holds the exports of table 1, stage 2 the exports of
-- table 2, and so on
-- ============================================================

CREATE STAGE CUSTOMER_EXPORT_STAGE_1
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_1;

CREATE STAGE CUSTOMER_EXPORT_STAGE_2
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_2;

CREATE STAGE CUSTOMER_EXPORT_STAGE_3
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_3;

CREATE STAGE CUSTOMER_EXPORT_STAGE_4
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_4;


-- ============================================================
-- 8. CREATE THE FOUR TASKS
-- Each task runs every 1 minute.
-- Each task is created in SUSPENDED state by default.
-- Each task generates a unique CSV filename using the current
-- timestamp and exports its own table to its own stage.
-- ============================================================

CREATE TASK EMPLOYEE_TASK_1
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_data_1_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE_1/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE_DATA_1';

END;


CREATE TASK EMPLOYEE_TASK_2
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_data_2_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE_2/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE_DATA_2';

END;


CREATE TASK EMPLOYEE_TASK_3
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_data_3_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE_3/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE_DATA_3';

END;


CREATE TASK EMPLOYEE_TASK_4
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_data_4_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE_4/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE_DATA_4';

END;


-- ============================================================
-- 9. CHECK THE FOUR TASKS
-- All four tasks should currently be SUSPENDED.
-- ============================================================

SHOW TASKS LIKE 'EMPLOYEE_TASK_%';


-- ============================================================
-- 10. RESUME THE FOUR TASKS
-- Starts the scheduler for all four tasks.
-- From now on every task runs every 1 minute.
-- ============================================================

ALTER TASK EMPLOYEE_TASK_1 RESUME;
ALTER TASK EMPLOYEE_TASK_2 RESUME;
ALTER TASK EMPLOYEE_TASK_3 RESUME;
ALTER TASK EMPLOYEE_TASK_4 RESUME;

-- Verify task state
SHOW TASKS LIKE 'EMPLOYEE_TASK_%';


-- ============================================================
-- 11. CHECK TASK HISTORY
-- Shows previous/current executions of all four tasks from the
-- last 1 hour. Also displays the next 5 expected execution
-- times for each task.
-- ============================================================

WITH TASK_NAMES AS (

    SELECT 'EMPLOYEE_TASK_1' AS TASK_NAME
    UNION ALL
    SELECT 'EMPLOYEE_TASK_2'
    UNION ALL
    SELECT 'EMPLOYEE_TASK_3'
    UNION ALL
    SELECT 'EMPLOYEE_TASK_4'
),

TASK_HISTORY_DATA AS (

    SELECT
        NAME,
        STATE,
        SCHEDULED_TIME,
        QUERY_START_TIME,
        COMPLETED_TIME,
        ERROR_MESSAGE

    FROM TABLE(
        INFORMATION_SCHEMA.TASK_HISTORY(
            SCHEDULED_TIME_RANGE_START =>
                DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
        )
    )

    -- Keep only the four tasks of this practice
    WHERE NAME IN (
        'EMPLOYEE_TASK_1',
        'EMPLOYEE_TASK_2',
        'EMPLOYEE_TASK_3',
        'EMPLOYEE_TASK_4'
    )
),

LATEST_SCHEDULE AS (

    SELECT
        MAX(SCHEDULED_TIME) AS LAST_SCHEDULED_TIME

    FROM TASK_HISTORY_DATA
),

NEXT_5_EXECUTIONS AS (

    SELECT
        TASK_NAME,

        DATEADD(
            MINUTE,
            ROW_NUMBER() OVER (
                PARTITION BY TASK_NAME
                ORDER BY SEQ4()
            ),
            LAST_SCHEDULED_TIME
        ) AS NEXT_SCHEDULE_TIME

    FROM TASK_NAMES,
         LATEST_SCHEDULE,
         TABLE(GENERATOR(ROWCOUNT => 5))
)

-- ============================================================
-- Previous / Current Task Executions
-- ============================================================

SELECT

    NAME AS TASK_NAME,

    CASE
        WHEN STATE = 'SUCCEEDED' THEN 'SUCCESS'
        WHEN STATE = 'EXECUTING' THEN 'RUNNING'
        WHEN STATE = 'FAILED' THEN 'FAILED'
        WHEN STATE = 'SCHEDULED' THEN 'SCHEDULED'
        ELSE STATE
    END AS EXECUTION_STATUS,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            SCHEDULED_TIME
        ),
        'YYYY-MM-DD'
    ) AS EXECUTION_DATE_IST,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            SCHEDULED_TIME
        ),
        'HH12:MI:SS AM'
    ) || ' IST' AS SCHEDULED_TIME_IST,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            QUERY_START_TIME
        ),
        'HH12:MI:SS AM'
    ) || ' IST' AS START_TIME_IST,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            COMPLETED_TIME
        ),
        'HH12:MI:SS AM'
    ) || ' IST' AS COMPLETED_TIME_IST,

    DATEDIFF(
        'SECOND',
        QUERY_START_TIME,
        COMPLETED_TIME
    ) AS EXECUTION_SECONDS,

    ERROR_MESSAGE

FROM TASK_HISTORY_DATA


UNION ALL


-- ============================================================
-- Next 5 Expected Executions For Each Task
-- ============================================================

SELECT

    TASK_NAME,

    'UPCOMING' AS EXECUTION_STATUS,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            NEXT_SCHEDULE_TIME
        ),
        'YYYY-MM-DD'
    ) AS EXECUTION_DATE_IST,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            NEXT_SCHEDULE_TIME
        ),
        'HH12:MI:SS AM'
    ) || ' IST' AS SCHEDULED_TIME_IST,

    NULL AS START_TIME_IST,

    NULL AS COMPLETED_TIME_IST,

    NULL AS EXECUTION_SECONDS,

    NULL AS ERROR_MESSAGE

FROM NEXT_5_EXECUTIONS

ORDER BY
    SCHEDULED_TIME_IST DESC;


-- ============================================================
-- 12. CHECK THE EXPORTED FILES
-- Each stage should hold the CSV files of its own task
-- ============================================================

LIST @CUSTOMER_EXPORT_STAGE_1;
LIST @CUSTOMER_EXPORT_STAGE_2;
LIST @CUSTOMER_EXPORT_STAGE_3;
LIST @CUSTOMER_EXPORT_STAGE_4;


-- ============================================================
-- 13. SUSPEND THE FOUR TASKS
-- Stops future scheduled executions for all four tasks
-- ============================================================

ALTER TASK EMPLOYEE_TASK_1 SUSPEND;
ALTER TASK EMPLOYEE_TASK_2 SUSPEND;
ALTER TASK EMPLOYEE_TASK_3 SUSPEND;
ALTER TASK EMPLOYEE_TASK_4 SUSPEND;

-- Verify task state
SHOW TASKS LIKE 'EMPLOYEE_TASK_%';


-- ============================================================
-- 14. RESUME THE FOUR TASKS AGAIN
-- Starts the scheduler for all four tasks again
-- ============================================================

ALTER TASK EMPLOYEE_TASK_1 RESUME;
ALTER TASK EMPLOYEE_TASK_2 RESUME;
ALTER TASK EMPLOYEE_TASK_3 RESUME;
ALTER TASK EMPLOYEE_TASK_4 RESUME;

-- Verify task state
SHOW TASKS LIKE 'EMPLOYEE_TASK_%';
