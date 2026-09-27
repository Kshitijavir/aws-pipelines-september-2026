# 🧹 Cleanup — 55) Snowflake Upsert - MERGE Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

## 1️⃣ Drop Everything

```sql
-- 55) Snowflake Upsert - MERGE Pipeline
DROP TABLE IF EXISTS SNOWFLAKE_MERGE_PRACTICE.MERGE_SCHEMA.EMPLOYEE_SOURCE;
DROP TABLE IF EXISTS SNOWFLAKE_MERGE_PRACTICE.MERGE_SCHEMA.EMPLOYEE_TARGET;
DROP SCHEMA IF EXISTS SNOWFLAKE_MERGE_PRACTICE.MERGE_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_MERGE_PRACTICE;
DROP WAREHOUSE IF EXISTS MERGE_WH;
```

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE MERGE_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- This pipeline creates **no stage and no file format** — both tables are filled with `INSERT`, so only the two tables need dropping.
- `MERGE` only changes rows; it creates no object of its own, so there is nothing extra to clean up.
- `DROP SCHEMA` fails while the schema still holds objects, which is why the tables come first.
