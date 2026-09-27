# 🧹 Cleanup — 54) Snowflake SQL Transformation Pipeline

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

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

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE TRANSFORMATION_WH SUSPEND;
```

## 📌 Notes

- Every object name is fully qualified. That means it shows `DATABASE.SCHEMA.OBJECT`. So the script works from any session.
- This pipeline creates **no stage and no file format**. The raw rows are added with `INSERT`. So only the four tables need dropping.
- The three CTAS tables (`TRANSFORMED_EMPLOYEE`, `IT_EMPLOYEES`, `DEPARTMENT_SUMMARY`) are all made from `RAW_EMPLOYEE`. CTAS means Create Table As Select. So they are dropped before it.
- `DROP SCHEMA` fails if the schema still holds objects. That is why the tables come first.
