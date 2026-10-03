# 🧹 Cleanup — 64) S3 → EventBridge → Step Functions → Snowflake SP1 → SP2 Pipeline

This file removes every object this pipeline creates. Run the statements from top to bottom.

## 1️⃣ Drop Everything (Snowflake)

```sql
-- 64) S3 -> EventBridge -> Step Functions -> SP1 -> SP2 Pipeline
DROP PROCEDURE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.SP1_LOAD_STAGING(STRING);
DROP PROCEDURE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.SP2_LOAD_STAR_SCHEMA();
DROP STAGE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.RAW_S3_PIPELINE_STAGE;
DROP STORAGE INTEGRATION IF EXISTS S3_PIPELINE_INTEGRATION;
DROP FILE FORMAT IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.RAW_ORDERS_CSV_FORMAT;
DROP TABLE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.AUDIT_TABLE_1;
DROP TABLE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.AUDIT_TABLE_2;
DROP TABLE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.FACT_SALES;
DROP TABLE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.DIM_CUSTOMER;
DROP TABLE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.DIM_PRODUCT;
DROP TABLE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA.STAGING_ORDERS;
DROP SCHEMA IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE.PIPELINE_SCHEMA;
DROP DATABASE IF EXISTS SNOWFLAKE_STEP_FUNCTIONS_PIPELINE;
DROP WAREHOUSE IF EXISTS PIPELINE_WH;
```

> 📌 `SP1_LOAD_STAGING` is dropped with its argument list `(STRING)`, because that is how Snowflake identifies a procedure with parameters.

## 2️⃣ Delete the AWS Objects

Delete them in this order, bottom of the pipeline first. That way nothing is still pointing at something that is already gone.

```text
AWS
 ├── 1. Disable or delete the EventBridge rule snowflake-pipeline-file-arrival-rule
 ├── 2. Delete the state machine snowflake-pipeline-state-machine
 ├── 3. Delete the four Lambda functions
 │        snowflake-sp1-start-lambda
 │        snowflake-sp1-status-lambda
 │        snowflake-sp2-run-lambda
 │        snowflake-pipeline-email-lambda
 ├── 4. Delete the role SnowflakeStepFunctionsPracticeRole
 ├── 5. Delete the role SnowflakeStepFunctionsSnowflakeRole
 ├── 6. Empty the bucket snowflake-step-functions-pipeline-2026
 │        (the CSV file is still inside it)
 └── 7. Delete the bucket snowflake-step-functions-pipeline-2026
```

## 3️⃣ Turn Off the S3 Event Notification

On the bucket `snowflake-step-functions-pipeline-2026`:

```text
Properties → Event notifications → Amazon EventBridge
     Set to Off, or remove the notification, so no events are sent
     to EventBridge after the rule is gone.
```

## 4️⃣ Or Just Stop the Cost

```sql
-- Keeps every object, and stops the warehouse cost
ALTER WAREHOUSE PIPELINE_WH SUSPEND;
```

```text
AWS
 └── The step functions state machine only costs while it runs, and it
     stands still in a Wait state. Delete the EventBridge rule to stop
     new runs from starting.
```

## 📌 Notes

- Object names are full (`DATABASE.SCHEMA.OBJECT`), so the script works from any session.
- Drop the procedures first. They are the objects the Lambdas call.
- Drop the external stage **before** the storage integration it uses.
- `S3_PIPELINE_INTEGRATION` belongs to the whole account, not to the database, so it needs its own `DROP`.
- Drop the stage and the integration **before** you delete `SnowflakeStepFunctionsSnowflakeRole`. Otherwise Snowflake still points at a role that no longer exists.
- Delete the Lambdas before `SnowflakeStepFunctionsPracticeRole`. AWS refuses to delete a role that is still attached to a function or to a state machine.
- The state machine must be deleted before that role too, because the role is the state machine's execution role.
- Empty the S3 bucket before deleting it. AWS will not delete a bucket that still has objects, and the uploaded file is still inside it.
- While the EventBridge rule exists, **every** file uploaded to the bucket starts a run. Delete or disable the rule before you experiment with the bucket.
- The Snowflake audit tables (`AUDIT_TABLE_1`, `AUDIT_TABLE_2`) are dropped with the schema, so the run history goes with them. Export `SELECT * FROM AUDIT_TABLE_1` first if you want to keep a record.
