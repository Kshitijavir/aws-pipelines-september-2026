# 🧹 Cleanup — 52) Snowflake Table-to-Stage Export Pipeline

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 52) Snowflake Table-to-Stage Export Pipeline
DROP STAGE IF EXISTS SNOWFLAKE_UNLOAD_PRACTICE.EXPORT_SCHEMA.CUSTOMER_EXPORT_STAGE;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_UNLOAD_PRACTICE.EXPORT_SCHEMA.CUSTOMER_EXPORT_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_UNLOAD_PRACTICE.EXPORT_SCHEMA.CUSTOMER_EXPORT;
DROP SCHEMA IF EXISTS SNOWFLAKE_UNLOAD_PRACTICE.EXPORT_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_UNLOAD_PRACTICE;
DROP WAREHOUSE IF EXISTS EXPORT_WH;
```

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE EXPORT_WH SUSPEND;
```

## 📌 Notes

- The object names are written in full (`DATABASE.SCHEMA.OBJECT`). So this file works in any session.
- Small objects are dropped before the big object that holds them: stage → file format → table → schema → database.
- Dropping the stage removes the stage inside Snowflake. It also removes any files still left in the internal stage. The CSV file you downloaded sits on your computer. It is outside Snowflake, so it stays.
- `DROP SCHEMA` fails if the schema still has objects inside it. That is why the stage, file format and table are dropped first.
