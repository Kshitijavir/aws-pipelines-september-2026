# 🧹 Cleanup — 53) Snowflake Incremental File Load Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

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

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE INCREMENTAL_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- Children are dropped before parents: stage → file format → table → schema → database.
- `COPY_HISTORY` load metadata lives in the account, not in the database — `DROP TABLE` clears the table, but the load history for the dropped table's name is not something you delete manually.
- Also clear the 3 `sales_0X_*.csv` files from the internal stage if you are keeping the stage: `REMOVE @SALES_STAGE;`
