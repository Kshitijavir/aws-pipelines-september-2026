# 🧹 Cleanup — 63) Snowflake to S3 Export Pipeline (Multiple Tables → Multiple Buckets)

This file removes every Snowflake object that this pipeline creates, and then the AWS objects. Run the statements from top to bottom.

## 1️⃣ Drop Everything (Snowflake)

```sql
-- 63) Snowflake to S3 Export Pipeline — Multiple Tables to Multiple Buckets
DROP PROCEDURE IF EXISTS SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE.S3_MULTI_EXPORT_SCHEMA.EXPORT_STUDENT_AND_COLLEGE_TO_S3();
DROP STAGE IF EXISTS SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE.S3_MULTI_EXPORT_SCHEMA.STUDENT_S3_EXPORT_STAGE;
DROP STAGE IF EXISTS SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE.S3_MULTI_EXPORT_SCHEMA.COLLEGE_S3_EXPORT_STAGE;
DROP STORAGE INTEGRATION IF EXISTS S3_MULTI_EXPORT_INTEGRATION;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE.S3_MULTI_EXPORT_SCHEMA.MULTI_EXPORT_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE.S3_MULTI_EXPORT_SCHEMA.STUDENT_DATA;
DROP TABLE IF EXISTS SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE.S3_MULTI_EXPORT_SCHEMA.COLLEGE_DATA;
DROP SCHEMA IF EXISTS SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE.S3_MULTI_EXPORT_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE;
DROP WAREHOUSE IF EXISTS S3_MULTI_EXPORT_WH;
```

## 2️⃣ Delete the AWS Objects

```text
AWS
 ├── Delete the Lambda function snowflake-s3-multi-export-lambda
 ├── Delete the role SnowflakeS3MultiExportPracticeRole
 ├── Delete the role SnowflakeS3MultiExportSnowflakeRole
 ├── Empty the bucket snowflake-student-export-2026
 ├── Delete the bucket snowflake-student-export-2026
 ├── Empty the bucket snowflake-college-export-2026
 └── Delete the bucket snowflake-college-export-2026
```

## 3️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE S3_MULTI_EXPORT_WH SUSPEND;
```

## 📌 Notes

- Object names are full (`DATABASE.SCHEMA.OBJECT`). So the script works from any session.
- We drop the stored procedure first. It is the object Lambda calls.
- We drop **both** external stages **before** the storage integration they share.
- `S3_MULTI_EXPORT_INTEGRATION` belongs to the whole account. It is not inside the database. So it needs its own `DROP`. One integration serves both buckets.
- Drop both stages and the integration **before** you delete the AWS role. If you do not, Snowflake may still point at a role that is gone.
- Empty both S3 buckets before you delete them. AWS will not delete a bucket that still has objects. And `student_data.csv` / `college_data.csv` will still be inside them.
- Delete the Lambda function before `SnowflakeS3MultiExportPracticeRole`. AWS will not delete a role that is still attached to a function.
- `trust_policy_snowflake_role.json` ships with placeholders. Paste `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID` from `DESC INTEGRATION S3_MULTI_EXPORT_INTEGRATION` into it before you create the role.
