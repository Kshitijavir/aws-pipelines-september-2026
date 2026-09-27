# 🧹 Cleanup — 63) Snowflake to S3 Export Pipeline

Drops every Snowflake object this pipeline created, then the AWS objects. Run the statements top to bottom.

## 1️⃣ Drop Everything (Snowflake)

```sql
-- 63) Snowflake to S3 Export Pipeline
DROP PROCEDURE IF EXISTS SNOWFLAKE_S3_EXPORT_PRACTICE.S3_EXPORT_SCHEMA.EXPORT_STAFF_TO_S3();
DROP STAGE IF EXISTS SNOWFLAKE_S3_EXPORT_PRACTICE.S3_EXPORT_SCHEMA.STAFF_S3_EXPORT_STAGE;
DROP STORAGE INTEGRATION IF EXISTS S3_EXPORT_INTEGRATION;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_S3_EXPORT_PRACTICE.S3_EXPORT_SCHEMA.STAFF_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_S3_EXPORT_PRACTICE.S3_EXPORT_SCHEMA.STAFF_DATA;
DROP SCHEMA IF EXISTS SNOWFLAKE_S3_EXPORT_PRACTICE.S3_EXPORT_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_S3_EXPORT_PRACTICE;
DROP WAREHOUSE IF EXISTS S3_EXPORT_WH;
```

## 2️⃣ Delete the AWS Objects

```text
AWS
 ├── Delete the Lambda function snowflake-s3-export-lambda
 ├── Delete the role SnowflakeS3ExportPracticeRole
 ├── Delete the role SnowflakeS3ExportSnowflakeRole
 ├── Empty the bucket snowflake-s3-export-practice-2026
 └── Delete the bucket snowflake-s3-export-practice-2026
```

## 3️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE S3_EXPORT_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- The stored procedure is dropped first — it is the object Lambda calls.
- The external stage is dropped **before** the storage integration it references.
- `S3_EXPORT_INTEGRATION` is an **account-level** object, not something inside the database, which is why it needs its own `DROP`.
- Drop the stage and integration **before** deleting the IAM role, otherwise Snowflake may still reference a role that no longer exists.
- Empty the S3 bucket before deleting it — AWS refuses to delete a bucket that still holds objects, and `staff_data.csv` will still be there.
- Delete the Lambda function before `SnowflakeS3ExportPracticeRole` — a role still attached to a function cannot be deleted.
