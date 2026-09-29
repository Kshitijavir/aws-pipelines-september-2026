# 🧹 Cleanup — 57) Snowflake Simple Task-Based Scheduled Pipeline

This file removes every Snowflake object that this pipeline makes. Run the statements from top to bottom.

## 1️⃣ Suspend the Task

```sql
-- Stop the task before you drop it
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_TASK SUSPEND;
```

## 2️⃣ Drop Everything

```sql
-- 57) Snowflake Simple Task-Based Scheduled Pipeline
-- The task comes before the table it reads
DROP TASK IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_TASK;

DROP TABLE IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE;

DROP SCHEMA IF EXISTS SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_TASK_PRACTICE;
DROP WAREHOUSE IF EXISTS TASK_WH;
```

## 3️⃣ Or Just Stop the Cost

```sql
-- Stops the schedule and the cost, but keeps everything
ALTER TASK SNOWFLAKE_TASK_PRACTICE.TASK_SCHEMA.EMPLOYEE_TASK SUSPEND;
ALTER WAREHOUSE TASK_WH SUSPEND;
```

## 📌 Notes

- 🏷️ Object names are fully written out (`DATABASE.SCHEMA.OBJECT`). So the script works from anywhere.
- ⚡ There is one task: `EMPLOYEE_TASK`. It runs every 1 minute until you suspend it.
- 🛑 Stop the task before you drop it. A running schedule keeps going until you stop it, and every run uses the warehouse.
- 📋 This pipeline makes no stage and no file format. It only makes one table and one task.
