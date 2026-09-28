# 🧹 Cleanup — 52) Snowflake Multiple Table export to Multiple Stage

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 52) Snowflake - Multiple Table export to Multiple Stage
DROP STAGE IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA.CUSTOMER_EXPORT_STAGE_1;
DROP STAGE IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA.CUSTOMER_EXPORT_STAGE_2;
DROP STAGE IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA.CUSTOMER_EXPORT_STAGE_3;
DROP STAGE IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA.CUSTOMER_EXPORT_STAGE_4;
DROP FILE FORMAT IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA.CUSTOMER_CSV_EXPORT_FORMAT;
DROP TABLE IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA.CUSTOMER_DATA_1;
DROP TABLE IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA.CUSTOMER_DATA_2;
DROP TABLE IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA.CUSTOMER_DATA_3;
DROP TABLE IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA.CUSTOMER_DATA_4;
DROP SCHEMA IF EXISTS CUSTOMER_EXPORT_DB.CUSTOMER_EXPORT_SCHEMA;
DROP DATABASE IF EXISTS CUSTOMER_EXPORT_DB;
DROP WAREHOUSE IF EXISTS CUSTOMER_EXPORT_WH;
```

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE CUSTOMER_EXPORT_WH SUSPEND;
```

## 📌 Notes

- The object names are written in full (`DATABASE.SCHEMA.OBJECT`). So this file works in any session.
- This pipeline makes **four** stages and **four** tables, so every one of them needs its own `DROP`. Missing one leaves a leftover object behind.
- Small objects are dropped before the big object that holds them: stages → file format → tables → schema → database.
- Dropping a stage removes the stage inside Snowflake. It also removes any files still left in that internal stage. The CSV files you downloaded sit on your computer. They are outside Snowflake, so they stay.
- `DROP SCHEMA` fails if the schema still has objects inside it. That is why the stages, file format and tables are dropped first. Add `CASCADE` only if you want one statement to delete everything inside the schema.
- This cleanup is only for `02) Multiple Table export to Multiple Stage`. The other demo in this folder uses different object names, so run its own `cleanup.md` too if you built it.
