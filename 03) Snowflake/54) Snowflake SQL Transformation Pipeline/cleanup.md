# 🧹 Cleanup — 54) Snowflake SQL Transformation Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

## 1️⃣ Drop Everything

```sql
-- 54) Snowflake SQL Transformation Pipeline
DROP TABLE IF EXISTS SNOWFLAKE_TRANSFORMATION_PRACTICE.TRANSFORMATION_SCHEMA.DEPARTMENT_SUMMARY;
DROP TABLE IF EXISTS SNOWFLAKE_TRANSFORMATION_PRACTICE.TRANSFORMATION_SCHEMA.IT_EMPLOYEES;
DROP TABLE IF EXISTS SNOWFLAKE_TRANSFORMATION_PRACTICE.TRANSFORMATION_SCHEMA.TRANSFORMED_EMPLOYEE;
DROP TABLE IF EXISTS SNOWFLAKE_TRANSFORMATION_PRACTICE.TRANSFORMATION_SCHEMA.RAW_EMPLOYEE;
DROP SCHEMA IF EXISTS SNOWFLAKE_TRANSFORMATION_PRACTICE.TRANSFORMATION_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_TRANSFORMATION_PRACTICE;
DROP WAREHOUSE IF EXISTS TRANSFORMATION_WH;
```

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE TRANSFORMATION_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- This pipeline creates **no stage and no file format** — the raw rows are added with `INSERT`, so only the four tables need dropping.
- The three `CREATE TABLE AS SELECT` tables (`TRANSFORMED_EMPLOYEE`, `IT_EMPLOYEES`, `DEPARTMENT_SUMMARY`) are all built from `RAW_EMPLOYEE`, so they are dropped before it.
- `DROP SCHEMA` fails while the schema still holds objects, which is why the tables come first.
