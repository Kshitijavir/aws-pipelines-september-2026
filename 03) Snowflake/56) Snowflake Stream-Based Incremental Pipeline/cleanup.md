# 🧹 Cleanup — 56) Snowflake Stream-Based Incremental Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

## 1️⃣ Drop Everything

```sql
-- 56) Snowflake Stream-Based Incremental Pipeline
DROP STREAM IF EXISTS SNOWFLAKE_STREAM_PRACTICE.STREAM_SCHEMA.EMPLOYEE_STREAM;
DROP TABLE IF EXISTS SNOWFLAKE_STREAM_PRACTICE.STREAM_SCHEMA.EMPLOYEE_FINAL;
DROP TABLE IF EXISTS SNOWFLAKE_STREAM_PRACTICE.STREAM_SCHEMA.EMPLOYEE_TARGET;
DROP TABLE IF EXISTS SNOWFLAKE_STREAM_PRACTICE.STREAM_SCHEMA.EMPLOYEE_SOURCE;
DROP SCHEMA IF EXISTS SNOWFLAKE_STREAM_PRACTICE.STREAM_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_STREAM_PRACTICE;
DROP WAREHOUSE IF EXISTS STREAM_WH;
```

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE STREAM_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- `EMPLOYEE_STREAM` is a stream **on** `EMPLOYEE_SOURCE`, so it is dropped before the source table. (Dropping the table would drop the stream anyway — doing it explicitly keeps the order obvious.)
- Once you drop the schema, any **stale stream** in it goes too; a stale stream is what you get when its table is dropped or recreated without the stream being consumed.
- This pipeline creates no stage and no file format — only tables and one stream.
