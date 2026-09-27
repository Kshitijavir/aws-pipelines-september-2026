# 🧹 Cleanup — 50) Snowflake Basic CSV Batch Load Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

## 1️⃣ Drop Everything

```sql
-- 50) Snowflake Basic CSV Batch Load Pipeline
DROP STAGE IF EXISTS SNOWFLAKE_PRACTICE.EMPLOYEE_SCHEMA.EMPLOYEE_STAGE;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_PRACTICE.EMPLOYEE_SCHEMA.EMPLOYEE_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_PRACTICE.EMPLOYEE_SCHEMA.EMPLOYEE;
DROP SCHEMA IF EXISTS SNOWFLAKE_PRACTICE.EMPLOYEE_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_PRACTICE;
DROP WAREHOUSE IF EXISTS PRACTICE_WH;
```

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE PRACTICE_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context — no `USE DATABASE` needed.
- Children are dropped before parents: stage → file format → table → schema → database.
- `DROP SCHEMA` fails while the schema still holds objects, which is why the stage, file format and table come first. Add `CASCADE` only if you want one statement to take everything inside the schema with it.
- `DROP WAREHOUSE` is independent of the database, so it can run in any position.
