-- ============================================================
-- 57) Snowflake -- Task-Based Scheduled Pipeline
-- Every SQL statement from the README, in the same order.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- Tasks run SQL on their own schedule. Notes on starting and
-- stopping them are written as comments next to the statements.
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- Creates a separate database for the task practice
-- ============================================================

CREATE DATABASE SNOWFLAKE_TASK_PRACTICE;

-- Selects the database for the remaining operations
USE DATABASE SNOWFLAKE_TASK_PRACTICE;


-- ============================================================
-- 2. CREATE SCHEMA
-- Creates a schema to organize all project objects
-- ============================================================

CREATE SCHEMA TASK_SCHEMA;

-- Selects the schema for the remaining operations
USE SCHEMA TASK_SCHEMA;


-- ============================================================
-- 3. CREATE WAREHOUSE
-- Creates an XSMALL compute warehouse for this practice
-- ============================================================

CREATE WAREHOUSE TASK_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Selects the warehouse used to run the tasks and queries
USE WAREHOUSE TASK_WH;


-- ============================================================
-- 4. CREATE SOURCE TABLE
-- Creates the table that holds the original employee data
-- ============================================================

CREATE TABLE EMPLOYEE_SOURCE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);


-- ============================================================
-- 5. INSERT SAMPLE DATA
-- Inserts the starting employee rows into the source table
-- ============================================================

INSERT INTO EMPLOYEE_SOURCE VALUES
(8001, 'Rahul Sharma', 'IT', 85000),
(8002, 'Priya Patil', 'HR', 62000),
(8003, 'Amit Verma', 'Finance', 95000),
(8004, 'Sneha Joshi', 'IT', 78000),
(8005, 'Vikas Kumar', 'Sales', 58000);

-- Verifies the employee data inserted into the table
SELECT * FROM EMPLOYEE_SOURCE;


-- ============================================================
-- 6. CREATE TARGET TABLE
-- Creates the table that will hold the changed data
-- ============================================================

CREATE TABLE EMPLOYEE_TARGET (
    EMPLOYEE_ID     NUMBER,
    EMPLOYEE_NAME   VARCHAR(100),
    DEPARTMENT      VARCHAR(50),
    SALARY          NUMBER,
    SALARY_CATEGORY VARCHAR(20),
    LOAD_TIME       TIMESTAMP
);


-- ============================================================
-- 7. CREATE THE FIRST TASK
-- The task runs this INSERT by itself every 1 minute
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
-- Displays the task that was created
-- ============================================================

SHOW TASKS;


-- ============================================================
-- 9. RESUME THE TASK
-- A new task starts suspended, so start it to let the
-- scheduler run it
-- ============================================================

ALTER TASK EMPLOYEE_LOAD_TASK RESUME;


-- ============================================================
-- 10. CHECK THE TARGET TABLE
-- Wait 1 to 2 minutes, then check the rows the task added
-- ============================================================

SELECT * FROM EMPLOYEE_TARGET;


-- ============================================================
-- 11. CHECK TASK HISTORY
-- Shows when the task ran and whether it finished fine
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
-- Stops the task from starting new runs
-- ============================================================

ALTER TASK EMPLOYEE_LOAD_TASK SUSPEND;


-- ============================================================
-- 13. CREATE THE SUMMARY TABLE
-- Creates the table that will hold the department summary
-- ============================================================

CREATE TABLE DEPARTMENT_SUMMARY (
    DEPARTMENT      VARCHAR(50),
    EMPLOYEE_COUNT  NUMBER,
    TOTAL_SALARY    NUMBER,
    AVG_SALARY      NUMBER,
    LOAD_TIME       TIMESTAMP
);


-- ============================================================
-- 14. CREATE THE ROOT (PARENT) TASK
-- The parent task runs this INSERT by itself every 5 minutes
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
-- AFTER EMPLOYEE_ROOT_TASK means: don't run this task on its
-- own. It runs after the parent task works.
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
-- In a chain of tasks you start the child task first and then
-- the parent task, because the parent controls the schedule
-- ============================================================

-- Stops both tasks before starting the chain again
ALTER TASK DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK EMPLOYEE_ROOT_TASK SUSPEND;

-- Start the child task first
ALTER TASK DEPARTMENT_SUMMARY_TASK RESUME;

-- Then start the parent task
ALTER TASK EMPLOYEE_ROOT_TASK RESUME;


-- ============================================================
-- 17. SHOW TASKS
-- Shows the task graph (parent task and child task)
-- ============================================================

SHOW TASKS;


-- ============================================================
-- 18. CHECK TASK HISTORY FOR ALL TASKS
-- Shows when each task ran and whether it finished fine
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
-- Stops both tasks from running again and again
-- ============================================================

ALTER TASK DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK EMPLOYEE_ROOT_TASK SUSPEND;


-- ============================================================
-- 🚫 DO NOT RUN THE STATEMENT BELOW BY HAND
-- Who runs it : the Snowflake task scheduler
-- Why         : The tasks above run this INSERT on their own
--               schedule. Running it by hand adds extra rows
--               to EMPLOYEE_TARGET that did not come from the
--               task.
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
