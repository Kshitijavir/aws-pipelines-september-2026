-- ============================================================
-- 57) Snowflake -- Task-Based Scheduled Pipeline
-- All the SQL from the README, in the same order.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- A task runs SQL for you on a timer. Notes about starting and
-- stopping tasks are written as comments next to the statements.
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

-- Use this warehouse to run the tasks
USE WAREHOUSE TASK_WH;


-- ============================================================
-- 4. CREATE SOURCE TABLE
-- Makes the table that holds the employee data
-- ============================================================

CREATE TABLE EMPLOYEE_SOURCE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);

SELECT * FROM EMPLOYEE_SOURCE;


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- Adds the first employee rows
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(8001, 'Rahul Sharma', 'IT', 85000),
(8002, 'Priya Patil', 'HR', 62000),
(8003, 'Amit Verma', 'Finance', 95000),
(8004, 'Sneha Joshi', 'IT', 78000),
(8005, 'Vikas Kumar', 'Sales', 58000);

-- Checks the rows you just added
SELECT * FROM EMPLOYEE_SOURCE;


-- ============================================================
-- 6. CREATE TARGET TABLE
-- Makes the table that will hold the new rows
-- ============================================================

CREATE TABLE EMPLOYEE_TARGET (
    EMPLOYEE_ID     NUMBER,
    EMPLOYEE_NAME   VARCHAR(100),
    DEPARTMENT      VARCHAR(50),
    SALARY          NUMBER,
    SALARY_CATEGORY VARCHAR(20),
    LOAD_TIME       TIMESTAMP
);

SELECT * FROM EMPLOYEE_TARGET;


-- ============================================================
-- 7. CREATE THE FIRST TASK
-- The task does this INSERT for you, every 1 minute
-- ============================================================

CREATE TASK EMPLOYEE_LOAD_TASK
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
INSERT INTO EMPLOYEE_TARGET
SELECT
    EMPLOYEE_ID,
    UPPER(EMPLOYEE_NAME),
    DEPARTMENT,
    SALARY,
    CASE
        WHEN SALARY >= 100000 THEN 'HIGH'
        WHEN SALARY >= 70000  THEN 'MEDIUM'
        ELSE 'LOW'
    END,
    CURRENT_TIMESTAMP()
FROM EMPLOYEE_SOURCE;


-- ============================================================
-- 8. SHOW TASKS
-- Shows the task you made
-- ============================================================

SHOW TASKS;


-- ============================================================
-- 9. RESUME THE TASK
-- A new task starts stopped. Start it, so the timer
-- can run it
-- ============================================================

ALTER TASK EMPLOYEE_LOAD_TASK RESUME;


-- ============================================================
-- 10. CHECK THE TARGET TABLE
-- Wait 1 or 2 minutes, then look at the new rows
-- ============================================================

SELECT * FROM EMPLOYEE_TARGET;


-- ============================================================
-- 11. CHECK TASK HISTORY
-- Shows when the task ran and if it went fine
-- ============================================================

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'EMPLOYEE_LOAD_TASK',
        SCHEDULED_TIME_RANGE_START => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY SCHEDULED_TIME DESC;


-- ============================================================
-- 12. SUSPEND THE TASK
-- Stops the task, so it does not run again
-- ============================================================

ALTER TASK EMPLOYEE_LOAD_TASK SUSPEND;


-- ============================================================
-- 13. CREATE THE SUMMARY TABLE
-- Makes the table for the department summary
-- ============================================================

CREATE TABLE DEPARTMENT_SUMMARY (
    DEPARTMENT      VARCHAR(50),
    EMPLOYEE_COUNT  NUMBER,
    TOTAL_SALARY    NUMBER,
    AVG_SALARY      NUMBER,
    LOAD_TIME       TIMESTAMP
);

SELECT * FROM DEPARTMENT_SUMMARY;


-- ============================================================
-- 14. CREATE THE ROOT (PARENT) TASK
-- The parent task does this INSERT for you, every 5 minutes
-- ============================================================

CREATE TASK EMPLOYEE_ROOT_TASK
    WAREHOUSE = TASK_WH
    SCHEDULE = '5 MINUTE'
AS
INSERT INTO EMPLOYEE_TARGET
SELECT
    EMPLOYEE_ID,
    UPPER(EMPLOYEE_NAME),
    DEPARTMENT,
    SALARY,
    CASE
        WHEN SALARY >= 100000 THEN 'HIGH'
        WHEN SALARY >= 70000  THEN 'MEDIUM'
        ELSE 'LOW'
    END,
    CURRENT_TIMESTAMP()
FROM EMPLOYEE_SOURCE;


-- ============================================================
-- 15. CREATE THE CHILD TASK
-- AFTER EMPLOYEE_ROOT_TASK means: this task does not run on
-- its own. It runs after the parent task.
-- ============================================================

CREATE TASK DEPARTMENT_SUMMARY_TASK
    WAREHOUSE = TASK_WH
    AFTER EMPLOYEE_ROOT_TASK
AS
INSERT INTO DEPARTMENT_SUMMARY
SELECT
    DEPARTMENT,
    COUNT(*),
    SUM(SALARY),
    AVG(SALARY),
    CURRENT_TIMESTAMP()
FROM EMPLOYEE_TARGET
GROUP BY DEPARTMENT;


-- ============================================================
-- 16. SUSPEND BOTH, THEN RESUME THE CHILD FIRST
-- In a chain, start the child task first, then the parent.
-- The parent task holds the timer.
-- ============================================================

-- Stop both tasks first
ALTER TASK DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK EMPLOYEE_ROOT_TASK SUSPEND;

-- Start this one first
ALTER TASK DEPARTMENT_SUMMARY_TASK RESUME;

-- Then start the parent task
ALTER TASK EMPLOYEE_ROOT_TASK RESUME;


-- ============================================================
-- 17. SHOW TASKS
-- Shows the parent task and the child task
-- ============================================================

SHOW TASKS;


-- ============================================================
-- 18. CHECK TASK HISTORY FOR ALL TASKS
-- Shows when each task ran and if it went fine
-- ============================================================

SELECT
    NAME,
    STATE,
    SCHEDULED_TIME,
    QUERY_START_TIME,
    COMPLETED_TIME,
    ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        SCHEDULED_TIME_RANGE_START = DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY SCHEDULED_TIME DESC;


-- ============================================================
-- 19. SUSPEND EVERYTHING
-- Stops both tasks, so they do not run again
-- ============================================================

ALTER TASK DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK EMPLOYEE_ROOT_TASK SUSPEND;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND
-- Who runs it : the Snowflake task scheduler
-- Why         : The tasks above run this INSERT for you, on a
--               timer. If you run it by hand, you add rows to
--               EMPLOYEE_TARGET that the timer did not add.
-- ============================================================

-- INSERT INTO EMPLOYEE_TARGET
-- SELECT
--     EMPLOYEE_ID,
--     UPPER(EMPLOYEE_NAME),
--     DEPARTMENT,
--     SALARY,
--     CASE
--         WHEN SALARY >= 100000 THEN 'HIGH'
--         WHEN SALARY >= 70000  THEN 'MEDIUM'
--         ELSE 'LOW'
--     END,
--     CURRENT_TIMESTAMP()
-- FROM EMPLOYEE_SOURCE;
