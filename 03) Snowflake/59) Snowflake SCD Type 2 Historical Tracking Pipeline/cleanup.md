# 🧹 Cleanup — 59) Snowflake SCD Type 2 Historical Tracking Pipeline

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 59) Snowflake SCD Type 2 Historical Tracking Pipeline
DROP TABLE IF EXISTS SNOWFLAKE_SCD2_PRACTICE.SCD2_SCHEMA.CUSTOMER_HISTORY;
DROP TABLE IF EXISTS SNOWFLAKE_SCD2_PRACTICE.SCD2_SCHEMA.CUSTOMER_SOURCE;
DROP SCHEMA IF EXISTS SNOWFLAKE_SCD2_PRACTICE.SCD2_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_SCD2_PRACTICE;
DROP WAREHOUSE IF EXISTS SCD2_WH;
```

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE SCD2_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`). So the script works from any session.
- This pipeline creates **no stage, no file format and no stored procedure**. The source rows are added with `INSERT`. The history table is kept with `MERGE`. So only the two tables need dropping.
- To reset the practice and keep the tables, just clear the rows:
  ```sql
  TRUNCATE TABLE SNOWFLAKE_SCD2_PRACTICE.SCD2_SCHEMA.CUSTOMER_HISTORY;
  ```
- `DROP SCHEMA` fails if the schema still holds objects. That is why the tables come first.
