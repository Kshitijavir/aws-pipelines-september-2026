# 🧹 Cleanup — 57) Snowflake Task-Based Scheduled Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

## 1️⃣ Suspend the Tasks

```sql
-- A started task should be suspended before you drop it
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_ROOT_TASK SUSPEND;
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_LOAD_TASK SUSPEND;
```

## 2️⃣ Drop Everything

```sql
-- 57) Snowflake Task-Based Scheduled Pipeline
-- Child task first, then the root task it hangs off
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

## 3️⃣ Or Just Stop the Compute

```sql
-- Stops the schedule and the billing without removing anything
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_ROOT_TASK SUSPEND;
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_LOAD_TASK SUSPEND;
ALTER WAREHOUSE TASK_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- Three tasks exist: `EMPLOYEE_ROOT_TASK` (the DAG root), `DEPARTMENT_SUMMARY_TASK` (a child that runs `AFTER EMPLOYEE_ROOT_TASK`) and `EMPLOYEE_LOAD_TASK` (standalone, the first task from Step 7).
- Drop the child before the root task it depends on.
- Suspend before dropping — a running schedule keeps firing until it is suspended, and `TASK_HISTORY` will keep growing.
- This pipeline creates no stage and no file format — only tables and tasks.
