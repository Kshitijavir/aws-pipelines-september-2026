# 🧹 Cleanup — 62) Lambda trigger Snowflake

This file removes every Snowflake object that this pipeline creates. Then it removes the AWS objects. Run the statements from top to bottom.

## 1️⃣ Drop Everything (Snowflake)

```sql
-- ============================================================
-- 62) LAMBDA TRIGGER SNOWFLAKE
-- ============================================================
DROP PROCEDURE IF EXISTS LAMBDA_SP_EXPORT_PRACTICE.LAMBDA_EXPORT_SCHEMA.EXPORT_EMPLOYEE_DATA();
DROP STAGE IF EXISTS LAMBDA_SP_EXPORT_PRACTICE.LAMBDA_EXPORT_SCHEMA.EMPLOYEE_EXPORT_STAGE;
DROP FILE FORMAT IF EXISTS LAMBDA_SP_EXPORT_PRACTICE.LAMBDA_EXPORT_SCHEMA.EMPLOYEE_CSV_FORMAT;
DROP TABLE IF EXISTS LAMBDA_SP_EXPORT_PRACTICE.LAMBDA_EXPORT_SCHEMA.EMPLOYEE_DATA;
DROP SCHEMA IF EXISTS LAMBDA_SP_EXPORT_PRACTICE.LAMBDA_EXPORT_SCHEMA;
DROP DATABASE IF EXISTS LAMBDA_SP_EXPORT_PRACTICE;
DROP WAREHOUSE IF EXISTS LAMBDA_EXPORT_WH;
```

## 2️⃣ Delete the AWS Objects

```text
AWS
 ├── Delete the Lambda function that runs lambda_function.py
 └── Delete its IAM execution role (the one whose trust policy
     lets lambda.amazonaws.com assume it — see trust_policy.json)
```

## 3️⃣ Or Just Stop the Cost

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE LAMBDA_EXPORT_WH SUSPEND;
```

## 📌 Notes

- Each object name is fully written out (`DATABASE.SCHEMA.OBJECT`). So the script works from any session.
- The saved procedure is dropped first, because it is the object Lambda calls. The stage and the file format come next, before the table they belong to.
- The export target is a Snowflake **internal stage**. That is a landing spot for files inside Snowflake. So there is no S3 bucket or S3 object to delete in this pipeline.
- Delete the Lambda function before its IAM role. A role that is still attached to a function cannot be deleted.
