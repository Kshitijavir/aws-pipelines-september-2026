# 🧹 Cleanup — 51) Snowflake Multiple CSV to Multiple Tables

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 51) Snowflake - Multiple CSV to Multiple Tables
DROP STAGE IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_STAGE_1;
DROP STAGE IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_STAGE_2;
DROP STAGE IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_STAGE_3;
DROP STAGE IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_STAGE_4;
DROP FILE FORMAT IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_CSV_FORMAT;
DROP TABLE IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_DATA_1;
DROP TABLE IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_DATA_2;
DROP TABLE IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_DATA_3;
DROP TABLE IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA.EMPLOYEE_DATA_4;
DROP SCHEMA IF EXISTS MULTI_TABLE_LOAD_DB.EMPLOYEE_LOAD_SCHEMA;
DROP DATABASE IF EXISTS MULTI_TABLE_LOAD_DB;
DROP WAREHOUSE IF EXISTS EMPLOYEE_LOAD_WH;
```

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE EMPLOYEE_LOAD_WH SUSPEND;
```

## 📌 Notes

- The object names are written in full (`DATABASE.SCHEMA.OBJECT`), so this file works in any session. You do not need to run `USE DATABASE` first.
- This pipeline makes **four** stages and **four** tables, so every one of them needs its own `DROP`. Missing one leaves a leftover object behind.
- Small objects are dropped before the big object that holds them: stages → file format → tables → schema → database.
- `DROP SCHEMA` fails if the schema still has objects inside it. That is why the stages, file format and tables are dropped first. Add `CASCADE` only if you want one statement to delete everything inside the schema.
- The four `employees_0X.csv` files in `input file/` are files on your computer. The drops above do not touch them.
- This cleanup is only for `02) Multiple CSV to Multiple Tables`. The other demo in this folder uses different object names, so run its own `cleanup.md` too if you built it.
