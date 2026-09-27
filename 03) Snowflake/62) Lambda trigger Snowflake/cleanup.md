# 🧹 Cleanup — 62) Lambda trigger Snowflake

Drops every Snowflake object this pipeline created, then the AWS objects. Run the statements top to bottom.

## 1️⃣ Drop Everything (Snowflake)

```sql
-- 62) Lambda trigger Snowflake
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

## 3️⃣ Or Just Stop the Compute

```sql
-- Keeps every object, stops the billing
ALTER WAREHOUSE LAMBDA_EXPORT_WH SUSPEND;
```

## 📌 Notes

- Object names are fully qualified (`DATABASE.SCHEMA.OBJECT`), so the script works from any session context.
- The stored procedure is dropped first because it is the object Lambda calls; the stage and file format follow before the table they belong to.
- The export target is a Snowflake **internal stage**, so there is no S3 bucket or S3 object to delete for this pipeline.
- Delete the Lambda function before its IAM role — a role still attached to a function cannot be deleted.
