# 🧹 Cleanup — 60) End-to-End Snowflake Data Pipeline

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

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

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE E2E_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- `CUSTOMER_FINAL` is built from `CUSTOMER_RAW`, so the transformed table is dropped first.
- The stage is dropped before the table it feeds, and the file format after the stage that uses it.
- The `customer.csv` in `input files/` is a local file — the drops above do not touch it.
- `DROP SCHEMA` fails while the schema still holds objects, which is why the stage, file format and tables come first.
