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
-- 4. CREATE EMPLOYEE TABLE
-- ============================================================

CREATE TABLE EMPLOYEE (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

-- Check the empty table
SELECT * FROM EMPLOYEE;


-- ============================================================
-- 5. INSERT EMPLOYEE DATA
-- ============================================================

INSERT INTO EMPLOYEE VALUES
(1001, 'Rahul', 'IT', 85000),
(1002, 'Priya', 'HR', 65000),
(1003, 'Amit', 'Finance', 95000),
(1004, 'Sneha', 'IT', 78000),
(1005, 'Vikas', 'Sales', 55000);

-- Verify inserted records
SELECT * FROM EMPLOYEE;


-- ============================================================
-- 6. CREATE FILE FORMAT
-- ============================================================

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_1
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';


-- ============================================================
-- 7. CREATE INTERNAL STAGE
-- ============================================================

CREATE STAGE CUSTOMER_EXPORT_STAGE
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_1;


-- ============================================================
-- 8. CREATE TASK
-- ============================================================
-- The task runs every 1 minute.
-- The task is created in SUSPENDED state by default.
-- It generates a unique CSV filename using the current timestamp
-- and exports the EMPLOYEE table to the internal stage.
-- ============================================================

CREATE TASK EMPLOYEE_TASK
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE';

END;


-- ============================================================
-- 9. CHECK TASK
-- ============================================================
-- The task should currently be SUSPENDED.
-- ============================================================

SHOW TASKS LIKE 'EMPLOYEE_TASK';


-- ============================================================
-- 10. RESUME TASK
-- ============================================================
-- Starts the task scheduler.
-- The task will execute every 1 minute.
-- ============================================================

ALTER TASK EMPLOYEE_TASK RESUME;

-- Verify task state
SHOW TASKS LIKE 'EMPLOYEE_TASK';


-- ============================================================
-- 11. CHECK TASK HISTORY
-- ============================================================
-- Shows previous/current executions from the last 1 hour.
-- Also displays the next 5 expected execution times.
-- ============================================================

WITH TASK_HISTORY_DATA AS (

    SELECT
        NAME,
        STATE,
        SCHEDULED_TIME,
        QUERY_START_TIME,
        COMPLETED_TIME,
        ERROR_MESSAGE

    FROM TABLE(
        INFORMATION_SCHEMA.TASK_HISTORY(
            TASK_NAME => 'EMPLOYEE_TASK',
            SCHEDULED_TIME_RANGE_START =>
                DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
        )
    )
),

LATEST_SCHEDULE AS (

    SELECT
        MAX(SCHEDULED_TIME) AS LAST_SCHEDULED_TIME

    FROM TASK_HISTORY_DATA
),

NEXT_5_EXECUTIONS AS (

    SELECT
        DATEADD(
            MINUTE,
            ROW_NUMBER() OVER (ORDER BY SEQ4()),
            LAST_SCHEDULED_TIME
        ) AS NEXT_SCHEDULE_TIME

    FROM LATEST_SCHEDULE,
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
-- Next 5 Expected Executions
-- ============================================================

SELECT

    'EMPLOYEE_TASK' AS TASK_NAME,

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
-- 12. SUSPEND TASK
-- ============================================================
-- Stops future scheduled executions.
-- ============================================================

ALTER TASK EMPLOYEE_TASK SUSPEND;

-- Verify task state
SHOW TASKS LIKE 'EMPLOYEE_TASK';


-- ============================================================
-- 13. RESUME TASK AGAIN
-- ============================================================
-- Starts the scheduler again.
-- The task will continue running every 1 minute.
-- ============================================================

ALTER TASK EMPLOYEE_TASK RESUME;

-- Verify task state
SHOW TASKS LIKE 'EMPLOYEE_TASK';