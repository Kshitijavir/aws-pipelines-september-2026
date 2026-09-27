# 🧹 Cleanup — 61) Snowflake Star Schema ETL with Stored Procedure & Audit

Drops every Snowflake object this pipeline created. Run the statements top to bottom.

## 1️⃣ Drop Everything

```sql
-- 61) Snowflake Star Schema ETL with Stored Procedure & Audit
-- SP_LOAD_STAGING contains CALL SP_LOAD_STAR_SCHEMA(), so drop the caller first
DROP PROCEDURE IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.SP_LOAD_STAGING();
DROP PROCEDURE IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.SP_LOAD_STAR_SCHEMA();

DROP STAGE IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.CUSTOMER_STAGE;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.CUSTOMER_CSV_FORMAT;

DROP TABLE IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.FACT_SALES;
DROP TABLE IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.DIM_CUSTOMER;
DROP TABLE IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.CUSTOMER_STAGING;
DROP TABLE IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.AUDIT_LOG;

DROP SCHEMA IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_STAR_SCHEMA_PRACTICE;
DROP WAREHOUSE IF EXISTS STAR_WH;
```

## 2️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE STAR_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- Two procedures exist. `SP_LOAD_STAGING` is the one that calls `CALL SP_LOAD_STAR_SCHEMA()`, so it is dropped before the procedure it calls.
- Drop order for the tables follows the data flow: fact → dimension → staging → audit.
- To reset the practice without dropping anything, clear the rows and the audit trail instead:
  ```sql
  TRUNCATE TABLE SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.FACT_SALES;
  TRUNCATE TABLE SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.DIM_CUSTOMER;
  TRUNCATE TABLE SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.CUSTOMER_STAGING;
  TRUNCATE TABLE SNOWFLAKE_STAR_SCHEMA_PRACTICE.STAR_SCHEMA.AUDIT_LOG;
  ```
- `DROP SCHEMA` fails while the schema still holds objects, which is why the procedures, stage, file format and tables come first.
