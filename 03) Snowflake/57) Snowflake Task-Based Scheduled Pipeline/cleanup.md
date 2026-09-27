# 🧹 Cleanup — 57) Snowflake Task-Based Scheduled Pipeline

This file removes every Snowflake object that this pipeline makes. Run the statements from top to bottom.

## 1️⃣ Suspend the Tasks

```sql
-- Stop a task before you drop it
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_ROOT_TASK SUSPEND;
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_LOAD_TASK SUSPEND;
```

## 2️⃣ Drop Everything

```sql
-- 57) Snowflake Task-Based Scheduled Pipeline
-- The next task comes first, then the parent task
DROP TASK IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.DEPARTMENT_SUMMARY_TASK;
DROP TASK IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_ROOT_TASK;
DROP TASK IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_LOAD_TASK;

DROP TABLE IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.DEPARTMENT_SUMMARY;
DROP TABLE IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_TARGET;
DROP TABLE IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_SOURCE;

DROP SCHEMA IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_TASK_PRACTICE;
DROP WAREHOUSE IF EXISTS TASK_WH;
```

## 3️⃣ Or Just Stop the Cost

```sql
-- Stops the schedule and the cost, but keeps everything
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_ROOT_TASK SUSPEND;
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_LOAD_TASK SUSPEND;
ALTER WAREHOUSE TASK_WH SUSPEND;
```

## 📌 Notes

- Object names are fully written out (`DATABASE.SCHEMA.OBJECT`). So the script works from anywhere.
- There are three tasks: `EMPLOYEE_ROOT_TASK` (the parent task), `DEPARTMENT_SUMMARY_TASK` (the task that runs after the parent, using `AFTER EMPLOYEE_ROOT_TASK`) and `EMPLOYEE_LOAD_TASK` (on its own, the first task from Step 7).
- Drop the later task before the parent task it needs.
- Stop tasks before you drop them. A running schedule keeps going until you stop it. Then `TASK_HISTORY` keeps getting bigger.
- This pipeline makes no stage and no file format. It only makes tables and tasks.
