# 🧹 Cleanup — 51) Snowflake Multi-File CSV Batch Load Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

## 1️⃣ Drop Everything

```sql
-- 51) Snowflake Multi-File CSV Batch Load Pipeline
DROP STAGE IF EXISTS SNOWFLAKE_MULTI_FILE_PRACTICE.MULTI_FILE_SCHEMA.EMPLOYEE_MULTI_STAGE;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_MULTI_FILE_PRACTICE.MULTI_FILE_SCHEMA.EMPLOYEE_MULTI_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_MULTI_FILE_PRACTICE.MULTI_FILE_SCHEMA.EMPLOYEE_MULTI;
DROP SCHEMA IF EXISTS SNOWFLAKE_MULTI_FILE_PRACTICE.MULTI_FILE_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_MULTI_FILE_PRACTICE;
DROP WAREHOUSE IF EXISTS MULTI_FILE_WH;
```

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE MULTI_FILE_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- Children are dropped before parents: stage → file format → table → schema → database.
- `DROP SCHEMA` fails while the schema still holds objects, which is why the stage, file format and table come first. Add `CASCADE` only if you want one statement to take everything inside the schema with it.
- The five `employees_0X.csv` files in `input file/` are local files — the drops above do not touch them.
