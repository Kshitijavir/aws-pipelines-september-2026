-- ============================================================
-- 57) Snowflake -- Simple Task-Based Scheduled Pipeline
-- All the SQL from the README, in the same order.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- A task runs SQL for you on a timer. Notes about starting and
-- stopping the task are written as comments next to the statements.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- Makes one database for this practice
-- ============================================================

CREATE DATABASE SNOWFLAKE_TASK_PRACTICE;

-- Use this database from now on
USE DATABASE SNOWFLAKE_TASK_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Makes a schema to hold all the objects
-- ============================================================

CREATE SCHEMA TASK_SCHEMA;

-- Use this schema from now on
USE SCHEMA TASK_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Makes a small warehouse to run the SQL
-- ============================================================

CREATE WAREHOUSE TASK_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Use this warehouse to run the task
USE WAREHOUSE TASK_WH;


-- ============================================================
-- 4. CREATE THE EMPLOYEE TABLE
-- Makes the table that holds the employee data
-- ============================================================

CREATE TABLE EMPLOYEE (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

-- The table is empty right now
SELECT * FROM EMPLOYEE;


-- ============================================================
-- 5. INSERT 5 RECORDS
-- Adds the five employee rows
-- ============================================================

INSERT INTO EMPLOYEE VALUES
(1001, 'Rahul', 'IT', 85000),
(1002, 'Priya', 'HR', 65000),
(1003, 'Amit', 'Finance', 95000),
(1004, 'Sneha', 'IT', 78000),
(1005, 'Vikas', 'Sales', 55000);

-- Checks the rows you just added
SELECT * FROM EMPLOYEE;


-- ============================================================
-- 6. CREATE THE TASK
-- The task runs this SQL every 1 minute
-- A new task always starts SUSPENDED, so it does not run yet
-- ============================================================

CREATE TASK EMPLOYEE_TASK
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
SELECT * FROM EMPLOYEE;


-- ============================================================
-- 7. CHECK THE TASK
-- STATE should say SUSPENDED here
-- ============================================================

SHOW TASKS LIKE 'EMPLOYEE_TASK';


-- ============================================================
-- 8. RESUME THE TASK
-- Starts the scheduler. From now on the task runs every minute
-- ============================================================

ALTER TASK EMPLOYEE_TASK RESUME;

-- STATE should say started now
SHOW TASKS LIKE 'EMPLOYEE_TASK';


-- ============================================================
-- 9. MONITOR TASK SCHEDULING AND EXECUTION
-- Shows the previous executions in IST, and the next 5 expected runs
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

-- Previous / current executions
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
        CONVERT_TIMEZONE('Asia/Kolkata', SCHEDULED_TIME),
        'YYYY-MM-DD'
    ) AS EXECUTION_DATE_IST,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', SCHEDULED_TIME),
        'HH12:MI:SS AM'
    ) || ' IST' AS SCHEDULED_TIME_IST,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', QUERY_START_TIME),
        'HH12:MI:SS AM'
    ) || ' IST' AS START_TIME_IST,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', COMPLETED_TIME),
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

-- Next 5 expected executions
SELECT
    'EMPLOYEE_TASK' AS TASK_NAME,

    'UPCOMING' AS EXECUTION_STATUS,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', NEXT_SCHEDULE_TIME),
        'YYYY-MM-DD'
    ) AS EXECUTION_DATE_IST,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', NEXT_SCHEDULE_TIME),
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
-- 10. SUSPEND THE TASK WHEN FINISHED
-- Stops future scheduled executions, so the task stops costing money
-- ============================================================

ALTER TASK EMPLOYEE_TASK SUSPEND;

-- STATE should say suspended now
SHOW TASKS LIKE 'EMPLOYEE_TASK';


-- ============================================================
-- 11. RESUME AGAIN WHEN YOU WANT TO PRACTICE
-- Starts the scheduler again
-- ============================================================

ALTER TASK EMPLOYEE_TASK RESUME;

-- STATE should say started again
SHOW TASKS LIKE 'EMPLOYEE_TASK';
