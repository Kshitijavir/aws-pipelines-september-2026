# 🧹 Cleanup — 59) Snowflake SCD Type 2 Historical Tracking Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

## 1️⃣ Drop Everything

```sql
-- 59) Snowflake SCD Type 2 Historical Tracking Pipeline
DROP TABLE IF EXISTS SNOWFLAKE_SCD2_PRACTICE.SCD2_SCHEMA.CUSTOMER_HISTORY;
DROP TABLE IF EXISTS SNOWFLAKE_SCD2_PRACTICE.SCD2_SCHEMA.CUSTOMER_SOURCE;
DROP SCHEMA IF EXISTS SNOWFLAKE_SCD2_PRACTICE.SCD2_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_SCD2_PRACTICE;
DROP WAREHOUSE IF EXISTS SCD2_WH;
```

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE SCD2_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- This pipeline creates **no stage, no file format and no stored procedure** — the source rows are added with `INSERT` and the history table is maintained with `MERGE`, so only the two tables need dropping.
- To reset the practice without dropping anything, keep the tables and clear the rows instead:
  ```sql
  TRUNCATE TABLE SNOWFLAKE_SCD2_PRACTICE.SCD2_SCHEMA.CUSTOMER_HISTORY;
  ```
- `DROP SCHEMA` fails while the schema still holds objects, which is why the tables come first.
