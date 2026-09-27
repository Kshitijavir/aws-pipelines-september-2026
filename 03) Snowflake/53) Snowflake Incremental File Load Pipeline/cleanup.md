# 🧹 Cleanup — 53) Snowflake Incremental File Load Pipeline

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 53) Snowflake Incremental File Load Pipeline
DROP STAGE IF EXISTS SNOWFLAKE_INCREMENTAL_PRACTICE.INCREMENTAL_SCHEMA.SALES_STAGE;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_INCREMENTAL_PRACTICE.INCREMENTAL_SCHEMA.SALES_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_INCREMENTAL_PRACTICE.INCREMENTAL_SCHEMA.SALES;
DROP SCHEMA IF EXISTS SNOWFLAKE_INCREMENTAL_PRACTICE.INCREMENTAL_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_INCREMENTAL_PRACTICE;
DROP WAREHOUSE IF EXISTS INCREMENTAL_WH;
```

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE INCREMENTAL_WH SUSPEND;
```

## 📌 Notes

- Every object name is fully qualified (`DATABASE.SCHEMA.OBJECT`). So the script works from any session.
- The child objects are dropped before their parents: stage → file format → table → schema → database.
- `COPY_HISTORY` load metadata (the record of which files were loaded) lives in the account, not in the database. `DROP TABLE` clears the table. But you do not delete the load history for that table name by hand.
- If you keep the stage, also clear the 3 `sales_0X_*.csv` files from it: `REMOVE @SALES_STAGE;`
