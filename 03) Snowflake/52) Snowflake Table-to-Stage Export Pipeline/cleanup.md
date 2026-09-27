# 🧹 Cleanup — 52) Snowflake Table-to-Stage Export Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

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

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE EXPORT_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- Children are dropped before parents: stage → file format → table → schema → database.
- Dropping the stage removes the Snowflake-side stage and any files still inside the internal stage — the CSV you downloaded to your computer is outside Snowflake and stays.
- `DROP SCHEMA` fails while the schema still holds objects, which is why the stage, file format and table come first.
