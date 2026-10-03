# 🧹 Cleanup — 63) Snowflake to S3 Export Pipeline (Multiple Tables → Single Bucket Partitions)

This file removes every Snowflake object that this pipeline creates, and then the AWS objects. Run the statements from top to bottom.

## 1️⃣ Drop Everything (Snowflake)

```sql
-- 63) Snowflake to S3 Export Pipeline — Multiple Tables to Single Bucket Partitions
DROP PROCEDURE IF EXISTS SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE.S3_PARTITION_EXPORT_SCHEMA.EXPORT_STUDENT_AND_COLLEGE_PARTITIONS_TO_S3();
DROP STAGE IF EXISTS SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE.S3_PARTITION_EXPORT_SCHEMA.PARTITION_S3_EXPORT_STAGE;
DROP STORAGE INTEGRATION IF EXISTS S3_PARTITION_EXPORT_INTEGRATION;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE.S3_PARTITION_EXPORT_SCHEMA.PARTITION_EXPORT_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE.S3_PARTITION_EXPORT_SCHEMA.STUDENT_RECORDS;
DROP TABLE IF EXISTS SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE.S3_PARTITION_EXPORT_SCHEMA.COLLEGE_RECORDS;
DROP SCHEMA IF EXISTS SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE.S3_PARTITION_EXPORT_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE;
DROP WAREHOUSE IF EXISTS S3_PARTITION_EXPORT_WH;
```

## 2️⃣ Delete the AWS Objects

```text
AWS
 ├── Delete the Lambda function snowflake-s3-partition-export-lambda
 ├── Delete the role SnowflakeS3PartitionExportPracticeRole
 ├── Delete the role SnowflakeS3PartitionExportSnowflakeRole
 ├── Empty the bucket snowflake-partition-export-2026. The student/ and
 │   college/ folders with student_records.csv and college_records.csv
 │   are still inside it.
 └── Delete the bucket snowflake-partition-export-2026
```

## 3️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE S3_PARTITION_EXPORT_WH SUSPEND;
```

## 📌 Notes

- Object names are full (`DATABASE.SCHEMA.OBJECT`). So the script works from any session.
- We drop the stored procedure first. It is the object Lambda calls.
- We drop the single external stage **before** the storage integration it uses.
- `S3_PARTITION_EXPORT_INTEGRATION` belongs to the whole account. It is not inside the database. So it needs its own `DROP`. One integration covers the whole bucket, which is why both the `student/` and `college/` folder are allowed.
- Drop the stage and the integration **before** you delete the AWS role. If you do not, Snowflake may still point at a role that is gone.
- Empty the S3 bucket before you delete it. AWS will not delete a bucket that still has objects — and both partitions are still inside it.
- The partition folders are not Snowflake objects, so there is nothing to drop for `student/` and `college/`. Deleting the files in the bucket removes them.
- Delete the Lambda function before `SnowflakeS3PartitionExportPracticeRole`. AWS will not delete a role that is still attached to a function.
- `trust_policy_snowflake_role.json` ships with placeholders. Paste `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID` from `DESC INTEGRATION S3_PARTITION_EXPORT_INTEGRATION` into it before you create the role.
