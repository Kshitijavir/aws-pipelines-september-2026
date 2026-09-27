# 🧹 Cleanup — 63) Snowflake to S3 Export Pipeline

This file removes every Snowflake object that this pipeline creates, and then the AWS objects. Run the statements from top to bottom.

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

## 3️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE S3_EXPORT_WH SUSPEND;
```

## 📌 Notes

- Object names are full (`DATABASE.SCHEMA.OBJECT`). So the script works from any session.
- We drop the stored procedure first. It is the object Lambda calls.
- We drop the external stage **before** the storage integration it uses.
- `S3_EXPORT_INTEGRATION` belongs to the whole account. It is not inside the database. So it needs its own `DROP`.
- Drop the stage and the integration **before** you delete the AWS role. If you do not, Snowflake may still point at a role that is gone.
- Empty the S3 bucket before you delete it. AWS will not delete a bucket that still has objects. And `staff_data.csv` will still be inside it.
- Delete the Lambda function before `SnowflakeS3ExportPracticeRole`. AWS will not delete a role that is still attached to a function.
