# 🧹 Cleanup — 55) Snowflake Upsert - MERGE Pipeline

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 55) Snowflake Upsert - MERGE Pipeline
DROP TABLE IF EXISTS SNOWFLAKE_MERGE_PRACTICE.MERGE_SCHEMA.EMPLOYEE_SOURCE;
DROP TABLE IF EXISTS SNOWFLAKE_MERGE_PRACTICE.MERGE_SCHEMA.EMPLOYEE_TARGET;
DROP SCHEMA IF EXISTS SNOWFLAKE_MERGE_PRACTICE.MERGE_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_MERGE_PRACTICE;
DROP WAREHOUSE IF EXISTS MERGE_WH;
```

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE MERGE_WH SUSPEND;
```

## 📌 Notes

- Every object name is written in full (`DATABASE.SCHEMA.OBJECT`). So the script works from any session.
- This pipeline creates **no stage and no file format**. Both tables get their rows with `INSERT`, so we only drop the two tables.
- `MERGE` only changes rows. It does not create any object, so there is nothing extra to clean up.
- `DROP SCHEMA` fails if the schema still has objects inside it. That is why the tables are dropped first.
