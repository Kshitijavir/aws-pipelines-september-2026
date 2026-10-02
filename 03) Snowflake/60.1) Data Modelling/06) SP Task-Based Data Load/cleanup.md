# 🧹 Cleanup — 60.1) Data Modelling → 06) SP Task-Based Data Load

This file removes every Snowflake object that this practice creates.
Run the statements from top to bottom.

> ⚠️ **Stop the Task FIRST.** A resumed Task keeps running every 1 minute and keeps using the
> warehouse. Suspending or dropping the Task is the most important step here.

## 1️⃣ Stop the Task

```sql
-- Stops the Task from running every minute
ALTER TASK IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.TASK_LOAD_DATA SUSPEND;
```

## 2️⃣ Drop Everything

```sql
-- 60.1) Data Modelling - 06) SP Task-Based Data Load
DROP TASK IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.TASK_LOAD_DATA;
DROP PROCEDURE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.SP_TASK_CHECK();
DROP PROCEDURE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.SP_LOAD_DATA();
DROP TABLE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.TASK_CHECK_AUDIT;
DROP TABLE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.SP_LOAD_AUDIT;
DROP TABLE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.STAGING_LOAD_AUDIT;
DROP TABLE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.CLAIM;
DROP TABLE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.PROVIDER;
DROP TABLE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.LOCATION;
DROP TABLE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.PRODUCT;
DROP TABLE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.CUSTOMER;
DROP TABLE IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.STAGING;
DROP SCHEMA IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA;
DROP DATABASE IF EXISTS SP_TASK_PRACTICE;
DROP WAREHOUSE IF EXISTS TASK_LOAD_WH;
```

## 3️⃣ Or Just Stop the Cost

Keep everything, but stop the two things that cost money:

```sql
-- Keeps all the objects, and stops the cost
ALTER TASK IF EXISTS SP_TASK_PRACTICE.SP_TASK_SCHEMA.TASK_LOAD_DATA SUSPEND;
ALTER WAREHOUSE IF EXISTS TASK_LOAD_WH SUSPEND;
```

## 📌 Notes

- **A Task is different from a table.** Even a tiny Task that just checks something still uses the
  warehouse for a few seconds every time it runs. So always stop the Task when you finish.
- A new Task is created **suspended**. It only starts running after `ALTER TASK ... RESUME`.
- Suspending a Task does **not** delete it. `DROP TASK` deletes it.
- The object names are written in full (`DATABASE.SCHEMA.OBJECT`), so this file works in any session.
  You do not need to run `USE DATABASE` first.
- Drop order (smallest to biggest): task → procedures → audit tables → target tables → `STAGING` →
  schema → database → warehouse.
- `DROP SCHEMA` fails if the schema still has objects inside it. That is why the task, both
  procedures and all 9 tables are dropped first. Add `CASCADE` only if you want one statement to
  delete everything inside the schema.
- The procedures are dropped before the tables, because a procedure points at the tables.
- The warehouse `TASK_LOAD_WH` is separate from the database. A warehouse sits at the account level,
  so it must be dropped (or suspended) on its own.
- There are **9 tables** in this practice:
  `STAGING`, `STAGING_LOAD_AUDIT`, `SP_LOAD_AUDIT`, `TASK_CHECK_AUDIT`,
  `CUSTOMER`, `PRODUCT`, `LOCATION`, `PROVIDER`, `CLAIM`.
