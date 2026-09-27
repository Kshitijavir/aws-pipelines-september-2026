# 🧹 Cleanup — 58) Snowflake Snowpipe Auto-Ingestion Pipeline

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

## 1️⃣ Pause the Pipe

```sql
-- Optional, but tidy: stop the pipe before you remove it
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

## 3️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost. Loading is stopped for now
ALTER PIPE SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA.EMPLOYEE_PIPE SET PIPE_EXECUTION_PAUSED = TRUE;
ALTER WAREHOUSE SNOWPIPE_WH SUSPEND;
```

## 📌 Notes

- Object names use the full path (`DATABASE.SCHEMA.OBJECT`). So the script works from anywhere.
- The pipe is removed **before** the stage and the file format it reads. It is also removed before the table it copies into.
- `COPY_HISTORY` keeps the pipe's load details for a while, even after the pipe is gone. You do not delete that history by hand.
- This Snowflake-only version uses `ALTER PIPE ... REFRESH` to start loading. So there is **no link from the cloud storage** and **no AWS object** to clean up:
  ```text
  AWS
   └── nothing to remove for this pipeline
  ```
