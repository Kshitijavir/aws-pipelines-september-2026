# 🧹 Cleanup — 58) Snowflake Snowpipe Auto-Ingestion Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

## 1️⃣ Pause the Pipe

```sql
-- Optional but tidy: stop the pipe from firing before you remove it
ALTER PIPE SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA.EMPLOYEE_PIPE SET PIPE_EXECUTION_PAUSED = TRUE;
```

## 2️⃣ Drop Everything

```sql
-- 58) Snowflake Snowpipe Auto-Ingestion Pipeline
DROP PIPE IF EXISTS SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA.EMPLOYEE_PIPE;
DROP STAGE IF EXISTS SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA.EMPLOYEE_STAGE;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA.EMPLOYEE_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA.EMPLOYEE;
DROP SCHEMA IF EXISTS SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_SNOWPIPE_PRACTICE;
DROP WAREHOUSE IF EXISTS SNOWPIPE_WH;
```

## 3️⃣ Or Just Stop the Compute

```sql
-- Keeps every object and pauses ingestion, stops the billing
ALTER PIPE SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA.EMPLOYEE_PIPE SET PIPE_EXECUTION_PAUSED = TRUE;
ALTER WAREHOUSE SNOWPIPE_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- The pipe is dropped **before** the stage and file format it reads through, and before the table it copies into.
- `COPY_HISTORY` keeps the pipe's load metadata for a while even after the pipe is gone — that history is not something you delete manually.
- This Snowflake-only version uses `ALTER PIPE ... REFRESH` to trigger ingestion, so there is **no notification integration and no AWS object** to clean up:
  ```text
  AWS
   └── nothing to remove for this pipeline
  ```
