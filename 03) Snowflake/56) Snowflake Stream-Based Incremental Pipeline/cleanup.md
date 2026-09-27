# 🧹 Cleanup — 56) Snowflake Stream-Based Incremental Pipeline

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

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

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE STREAM_WH SUSPEND;
```

## 📌 Notes

- The object names are fully written out (`DATABASE.SCHEMA.OBJECT`). So the script works from any session.
- `EMPLOYEE_STREAM` is a stream **on** `EMPLOYEE_SOURCE`. So we drop it before the source table. Dropping the table would drop the stream too. Doing it first keeps the order clear.
- When you drop the schema, any **stale stream** in it goes too. A stale stream shows up when its table was dropped or rebuilt, and the stream was never read.
- This pipeline makes no stage and no file format. It makes only tables and one stream.
