# 🧹 Cleanup — 51) Snowflake Multi-File CSV Batch Load Pipeline

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

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

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE MULTI_FILE_WH SUSPEND;
```

## 📌 Notes

- The object names are written in full (`DATABASE.SCHEMA.OBJECT`), so this file works in any session. You do not need to run `USE DATABASE` first.
- Small objects are dropped before the big object that holds them: stage → file format → table → schema → database.
- `DROP SCHEMA` fails if the schema still has objects inside it. That is why the stage, file format and table are dropped first. Add `CASCADE` only if you want one statement to delete everything inside the schema.
- The five `employees_0X.csv` files in `input file/` are files on your computer. The drops above do not touch them.
