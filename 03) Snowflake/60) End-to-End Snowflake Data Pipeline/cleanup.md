# 🧹 Cleanup — 60) End-to-End Snowflake Data Pipeline

This file removes every Snowflake object that this pipeline creates. Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 60) End-to-End Snowflake Data Pipeline
DROP STAGE IF EXISTS SNOWFLAKE_END_TO_END_PRACTICE.E2E_SCHEMA.CUSTOMER_STAGE;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_END_TO_END_PRACTICE.E2E_SCHEMA.CUSTOMER_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_END_TO_END_PRACTICE.E2E_SCHEMA.CUSTOMER_FINAL;
DROP TABLE IF EXISTS SNOWFLAKE_END_TO_END_PRACTICE.E2E_SCHEMA.CUSTOMER_RAW;
DROP SCHEMA IF EXISTS SNOWFLAKE_END_TO_END_PRACTICE.E2E_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_END_TO_END_PRACTICE;
DROP WAREHOUSE IF EXISTS E2E_WH;
```

## 2️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE E2E_WH SUSPEND;
```

## 📌 Notes

- The object names are written out in full (`DATABASE.SCHEMA.OBJECT`). So the script works from any session.
- `CUSTOMER_FINAL` is built from `CUSTOMER_RAW`. So we drop the changed table first.
- We drop the stage before the table it feeds. We drop the file format after the stage that uses it.
- The `customer.csv` in `input files/` is a file on your own computer. The drops above do not touch it.
- `DROP SCHEMA` fails while the schema still holds objects. That is why the stage, file format and tables come first.
