# 63) Snowflake to S3 Export Pipeline

> **Lambda Trigger → Stored Procedure → External Stage → Storage Integration → Amazon S3**

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [01) README.md](01%29%20README.md) | This guide |
| [snowflake.sql](snowflake.sql) | All the Snowflake objects — database, schema, warehouse (the machine that runs SQL), table, file format, storage integration, external stage and stored procedure |
| [lambda_function.py](lambda_function.py) | The function AWS calls first — it connects to Snowflake, runs the stored procedure, checks the file in S3 and writes logs to CloudWatch |
| [trust_policy_lambda_role.json](trust_policy_lambda_role.json) | The rule that says who can use `SnowflakeS3ExportPracticeRole` — it lets `lambda.amazonaws.com` use the role |
| [trust_policy_snowflake_role.json](trust_policy_snowflake_role.json) | The rule that says who can use `SnowflakeS3ExportSnowflakeRole` — it lets Snowflake's IAM identity use the role |

## 🎯 Goal

> 📌 **AWS Lambda starts a stored procedure in Snowflake. The procedure unloads `STAFF_DATA` with `COPY INTO`. It writes through a storage integration and an external stage. The data lands in Amazon S3 as one named CSV file — `staff_data.csv`. Lambda then checks the file with `LIST` and writes a clear log to CloudWatch.**

| Item | Value |
| ---- | ----- |
| Source table | `SNOWFLAKE_S3_EXPORT_PRACTICE.S3_EXPORT_SCHEMA.STAFF_DATA` |
| AWS destination | `s3://snowflake-s3-export-practice-2026/employee-export/staff_data.csv` |
| Trigger | AWS Lambda `snowflake-s3-export-lambda` (Python 3.12) |
| Lambda role | `SnowflakeS3ExportPracticeRole` |
| Snowflake role | `SnowflakeS3ExportSnowflakeRole` |

---

## 🧭 1. The Complete Picture

```mermaid
flowchart TD
    A["You click Test in Lambda"] --> B["AWS Lambda: snowflake-s3-export-lambda"]
    B --> C["IAM Role: SnowflakeS3ExportPracticeRole"]
    C --> D["Snowflake: CALL EXPORT_STAFF_TO_S3()"]
    D --> E["Stored Procedure: EXPORT_STAFF_TO_S3()"]
    E --> F["COPY INTO external stage"]
    F --> G["External Stage: STAFF_S3_EXPORT_STAGE"]
    G --> H["Storage Integration: S3_EXPORT_INTEGRATION"]
    H --> I["IAM Role: SnowflakeS3ExportSnowflakeRole"]
    I --> J["Amazon S3: employee-export/staff_data.csv"]
```

---

## 💡 2. First Understand the Business Idea

Snowflake contains:

```text
STAFF_DATA

STAFF_ID | STAFF_NAME | DEPARTMENT       | CITY      | SALARY
---------|------------|------------------|-----------|---------
201      | Kshitij    | Data Engineering | Pune      | 1200000
202      | Rahul      | AWS Engineering  | Mumbai    | 1000000
203      | Amit       | Data Analytics   | Bangalore | 900000
204      | Sneha      | Data Engineering | Pune      | 1100000
205      | Priya      | Cloud Engineering| Hyderabad | 1050000
```

Another process needs this data as a **CSV file in Amazon S3**.

Nobody logs in by hand to run `COPY INTO`. Instead, we let **AWS Lambda** start the export:

```text
Lambda
   ↓
"Snowflake, please export STAFF_DATA to S3."
   ↓
Snowflake does the export
```

This is the same idea as pipeline **62**. But there is one big change. The file does not stop inside Snowflake. It lands in **Amazon S3**.

| Pipeline | Where the exported file goes |
| -------- | ---------------------------- |
| 52 | Table → **Internal Stage** → CSV |
| 62 | Lambda → SP → **Internal Stage** → CSV |
| **63** | Lambda → SP → **External Stage → S3** → CSV |

---

## ⚡ 3. Why Do We Use Lambda?

Lambda is only the **outside trigger — the thing that starts the job**. It does not move the data itself.

```text
Lambda
   │  "Run the export"
   ▼
Snowflake Stored Procedure
   │  "Okay, I'll handle it"
   ▼
Data export
```

### 🧩 The Four Roles

| Component | What it does |
| --------- | ------------ |
| **Lambda** | Starts the job / checks the file / writes logs |
| **Stored Procedure** | Runs the export inside Snowflake |
| **External Stage** | A named S3 folder that Snowflake writes to |
| **Storage Integration** | The trust between Snowflake and the AWS role — no access keys |

---

## 📦 4. Why Use a Stored Procedure?

The export logic lives in Snowflake, not inside Python:

```sql
CREATE OR REPLACE PROCEDURE EXPORT_STAFF_TO_S3()
```

and internally:

```sql
COPY INTO @STAFF_S3_EXPORT_STAGE/staff_data.csv
FROM STAFF_DATA
FILE_FORMAT = (FORMAT_NAME = 'STAFF_CSV_FORMAT')
HEADER = TRUE
SINGLE = TRUE
OVERWRITE = TRUE;
```

So Lambda only needs to know one line:

```sql
CALL EXPORT_STAFF_TO_S3();
```

```text
Lambda                Stored Procedure
   │                        │
   │ Trigger only           │ Validation / transformation /
   └───────────────────────▶│ export / audit / status
```

---

## 🔐 5. Why Do We Need TWO IAM Roles?

**This is the most important idea in the pipeline.**

Two different AWS identities need to use a role. Their **trust rules are different**. So they cannot be the same role.

### Role 1 — `SnowflakeS3ExportPracticeRole`

This is **the role Lambda runs as**.

```text
AWS Lambda
     │ AssumeRole
     ▼
SnowflakeS3ExportPracticeRole
```

Its trust rule says:

```json
"Principal": { "Service": "lambda.amazonaws.com" }
```

Meaning:

> **The Lambda service is allowed to use this role.**

Policies attached to it:

| Policy | Do we need it? | Why |
| ------ | -------------- | --- |
| `AWSLambdaBasicExecutionRole` | ✅ Yes | Lets Lambda send log text to CloudWatch Logs |
| `AmazonS3FullAccess` | ⚠️ Not by this code | Lambda never touches S3 directly — it only calls Snowflake. We keep it here because this is a practice setup |

### Role 2 — `SnowflakeS3ExportSnowflakeRole`

This is **the role Snowflake uses to reach S3**. It is **never attached to Lambda**.

```text
Snowflake
     │ Storage Integration
     ▼
SnowflakeS3ExportSnowflakeRole
     │
     ▼
Amazon S3
```

Its trust rule says:

```json
"Principal": { "AWS": "arn:aws:iam::715831355129:user/une52000-s" }
```

Meaning:

> **Snowflake is allowed to use this role** — but only when the request carries the matching secret code (external ID).

Policy attached to it:

```text
SnowflakeS3ExportSnowflakeRole
        │
        └── AmazonS3FullAccess
```

| | Role 1 | Role 2 |
| ---- | ------ | ------ |
| Used by | Lambda | Snowflake |
| Attached to Lambda? | ✅ Yes | ❌ No |
| Who can use it | `lambda.amazonaws.com` | The Snowflake IAM user |
| `AWSLambdaBasicExecutionRole` | ✅ Yes | ❌ No |
| `AmazonS3FullAccess` | ✅ Attached | ✅ Attached |
| Used by the storage integration? | ❌ No | ✅ Yes |

> 🔑 **Remember it like this**
> Role 1 = *the identity Lambda uses*.
> Role 2 = *the identity Snowflake uses to reach S3*.

### Why can't we use one role?

Because a trust rule decides **who may use the role**. These two callers are different:

```text
Role 1 trusts:  lambda.amazonaws.com        → Lambda
Role 2 trusts:  arn:aws:iam::715831355129:user/une52000-s → Snowflake
```

One role cannot be trusted by Lambda *and* used by Snowflake for S3. That would break the rule to give only the permissions that are really needed. Two identities means two roles.

---

## 🏗️ 6. Correct Creation Order

The steps depend on each other. **The storage integration needs the AWS role ARN.** The **AWS role needs the values that `DESC INTEGRATION` returns**. So the order below matters.

```text
 1. Create the S3 bucket + employee-export/ prefix
        ↓
 2. Create Snowflake database, schema, warehouse, table, data, file format
        ↓
 3. Create the AWS role  SnowflakeS3ExportSnowflakeRole
        ↓
 4. Copy its Role ARN
        ↓
 5. Create the Snowflake storage integration
        ↓
 6. DESC INTEGRATION
        ↓
 7. Copy STORAGE_AWS_IAM_USER_ARN + STORAGE_AWS_EXTERNAL_ID
        ↓
 8. Paste them into the AWS trust policy (edit trust relationship)
        ↓
 9. Create the external stage
        ↓
10. LIST the stage  (proves Snowflake can reach S3)
        ↓
11. Create the stored procedure
        ↓
12. Create the Lambda function + role + Snowflake connector layer
```

---

## 🪣 Step 1 — Create the S3 Bucket

In the AWS Console:

```text
S3
 └── Create bucket
        Bucket name : snowflake-s3-export-practice-2026
        Region      : same region as your Snowflake account, if possible
```

Then create the folder (prefix):

```text
snowflake-s3-export-practice-2026
│
└── employee-export/
        │
        └── staff_data.csv        ← created later by Snowflake
```

> 📌 You do **not** need to make the bucket public. Only the AWS role gets access. And it gets access only through the storage integration.

---

## 🗄️ Step 2 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_S3_EXPORT_PRACTICE;

USE DATABASE SNOWFLAKE_S3_EXPORT_PRACTICE;
```

---

## 📂 Step 3 — Create the Schema

```sql
CREATE SCHEMA S3_EXPORT_SCHEMA;

USE SCHEMA S3_EXPORT_SCHEMA;
```

---

## ⚙️ Step 4 — Create the Warehouse

```sql
CREATE WAREHOUSE S3_EXPORT_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE S3_EXPORT_WH;
```

| Setting | What it means |
| ------- | ------------- |
| `WAREHOUSE_SIZE = 'XSMALL'` | The cheapest machine size — fine for practice |
| `AUTO_SUSPEND = 60` | It shuts down after 60 seconds of no use. So you are not billed while it sits idle |
| `AUTO_RESUME = TRUE` | It starts again by itself when a query needs it |

---

## 📋 Step 5 — Create the Source Table

```sql
CREATE TABLE STAFF_DATA (
    STAFF_ID NUMBER,
    STAFF_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(100),
    CITY VARCHAR(100),
    SALARY NUMBER
);

DESC TABLE STAFF_DATA;
```

---

## 📝 Step 6 — Insert Sample Data

```sql
INSERT INTO STAFF_DATA
    (STAFF_ID, STAFF_NAME, DEPARTMENT, CITY, SALARY)
VALUES
    (201, 'Kshitij', 'Data Engineering', 'Pune', 1200000),
    (202, 'Rahul', 'AWS Engineering', 'Mumbai', 1000000),
    (203, 'Amit', 'Data Analytics', 'Bangalore', 900000),
    (204, 'Sneha', 'Data Engineering', 'Pune', 1100000),
    (205, 'Priya', 'Cloud Engineering', 'Hyderabad', 1050000);

SELECT *
FROM STAFF_DATA;
```

Expected:

```text
+----------+------------+-------------------+-----------+---------+
| STAFF_ID | STAFF_NAME | DEPARTMENT        | CITY      | SALARY  |
|----------+------------+-------------------+-----------+---------|
|      201 | Kshitij    | Data Engineering  | Pune      | 1200000 |
|      202 | Rahul      | AWS Engineering   | Mumbai    | 1000000 |
|      203 | Amit       | Data Analytics    | Bangalore |  900000 |
|      204 | Sneha      | Data Engineering  | Pune      | 1100000 |
|      205 | Priya      | Cloud Engineering | Hyderabad | 1050000 |
+----------+------------+-------------------+-----------+---------+
```

---

## 📄 Step 7 — Create the CSV File Format

```sql
CREATE FILE FORMAT STAFF_CSV_FORMAT
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    COMPRESSION = 'NONE';

SHOW FILE FORMATS;
```

The generated file looks like:

```text
STAFF_ID,STAFF_NAME,DEPARTMENT,CITY,SALARY
201,Kshitij,Data Engineering,Pune,1200000
202,Rahul,AWS Engineering,Mumbai,1000000
...
```

> 📌 `SKIP_HEADER = 1` matters when you **read** a file back with this format. The header in the **exported** file comes from `HEADER = TRUE` in the `COPY INTO` statement.

---

## 🔐 Step 8 — Create the AWS Role for Snowflake

Create a role with:

```text
Trusted entity type : AWS account
Role name           : SnowflakeS3ExportSnowflakeRole
```

Start with a temporary trust rule. You will replace it in Step 12:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::715831355129:user/une52000-s" },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": { "sts:ExternalId": "XGC76761_SFCRole=4_j3ikOEOAHaRpt6s48NPBw54IHlA=" }
      }
    }
  ]
}
```

Attach `AmazonS3FullAccess` to this role. Then Snowflake can read and write the bucket.

Copy the **role ARN**:

```text
arn:aws:iam::772346609795:role/SnowflakeS3ExportSnowflakeRole
```

---

## 🔐 Step 9 — Create the AWS Lambda Execution Role

Create a second role:

```text
Trusted entity type : AWS service → Lambda
Role name           : SnowflakeS3ExportPracticeRole
Attached policies   : AWSLambdaBasicExecutionRole
                      AmazonS3FullAccess   (not required by this code)
```

The trust rule — see [trust_policy_lambda_role.json](trust_policy_lambda_role.json):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

> ⚠️ This Lambda code does **not use `AmazonS3FullAccess`**. Lambda calls Snowflake. Snowflake writes to S3. Keep it only because this is a practice setup. In a real job, remove it.

---

## 🔗 Step 10 — Create the Storage Integration

```sql
CREATE OR REPLACE STORAGE INTEGRATION S3_EXPORT_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN =
        'arn:aws:iam::772346609795:role/SnowflakeS3ExportSnowflakeRole'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://snowflake-s3-export-practice-2026/employee-export/'
    );
```

This tells Snowflake:

> "You may use this AWS role, but only for this S3 folder."

| Setting | What it means |
| ------- | ------------- |
| `TYPE = EXTERNAL_STAGE` | The integration is used by stages that point at S3 |
| `STORAGE_PROVIDER = S3` | The storage is Amazon S3 |
| `STORAGE_AWS_ROLE_ARN` | The role Snowflake will use |
| `STORAGE_ALLOWED_LOCATIONS` | The only folder Snowflake may touch |

> 📌 No AWS keys are stored anywhere. That is the whole point of a storage integration.

---

## 🔍 Step 11 — Describe the Integration

```sql
DESC INTEGRATION S3_EXPORT_INTEGRATION;
```

Look at two rows:

```text
+----------------------------+-----------------------------------------------------------+
| property                   | property_value                                            |
|----------------------------+-----------------------------------------------------------|
| STORAGE_AWS_IAM_USER_ARN   | arn:aws:iam::715831355129:user/une52000-s                 |
| STORAGE_AWS_EXTERNAL_ID    | XGC76761_SFCRole=4_j3ikOEOAHaRpt6s48NPBw54IHlA=           |
+----------------------------+-----------------------------------------------------------+
```

Where do these come from?

```text
Snowflake
   │
   │ DESC INTEGRATION
   ▼
IAM user ARN + External ID
   │
   ▼
AWS trust policy
```

> ⚠️ The IAM **user** ARN lives in Snowflake's AWS account. That is a *different* account (`715831355129`) from your role (`772346609795`). This is normal. Snowflake's identity uses a role **inside your account**.

---

## 🔐 Step 12 — Update the AWS Trust Policy

```text
AWS Console → IAM → Roles → SnowflakeS3ExportSnowflakeRole
            → Trust relationships → Edit trust policy
```

Paste — see [trust_policy_snowflake_role.json](trust_policy_snowflake_role.json):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::715831355129:user/une52000-s" },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": { "sts:ExternalId": "XGC76761_SFCRole=4_j3ikOEOAHaRpt6s48NPBw54IHlA=" }
      }
    }
  ]
}
```

Click **Update policy**.

> 📌 The `sts:ExternalId` condition stops another AWS account from tricking Snowflake into giving away data. Snowflake makes this secret code. You copy it. Only requests that carry it can use the role.

---

## 📥 Step 13 — Create the External Stage

```sql
CREATE OR REPLACE STAGE STAFF_S3_EXPORT_STAGE
    URL = 's3://snowflake-s3-export-practice-2026/employee-export/'
    STORAGE_INTEGRATION = S3_EXPORT_INTEGRATION
    FILE_FORMAT = STAFF_CSV_FORMAT;
```

Verify:

```sql
SHOW STAGES;

DESC STAGE STAFF_S3_EXPORT_STAGE;
```

`DESC STAGE` should show the S3 URL and:

```text
STORAGE_INTEGRATION = S3_EXPORT_INTEGRATION
```

---

## 🧪 Step 14 — Test S3 Connectivity

```sql
LIST @STAFF_S3_EXPORT_STAGE;
```

First run:

```text
+------+------+-----+---------------+
| name | size | md5 | last_modified |
|------+------+-----+---------------|
+------+------+-----+---------------+
```

How to read the result:

| Result | What it means |
| ------ | ------------- |
| **0 rows** | ✅ Normal — no file has been exported yet |
| **Access Denied** | ❌ The trust rule, the role ARN or the S3 permissions are wrong |
| **A file listed** | ✅ The export already ran |

> 📌 The goal of this step is simple: **no "Access Denied"**. That proves Snowflake can log in to AWS.

---

## ⚙️ Step 15 — Create the Stored Procedure

```sql
CREATE OR REPLACE PROCEDURE EXPORT_STAFF_TO_S3()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN

    COPY INTO @STAFF_S3_EXPORT_STAGE/staff_data.csv
    FROM STAFF_DATA
    FILE_FORMAT = (
        FORMAT_NAME = 'STAFF_CSV_FORMAT'
    )
    HEADER = TRUE
    SINGLE = TRUE
    OVERWRITE = TRUE;

    RETURN 'SUCCESS: Staff data successfully exported to S3 as staff_data.csv';

END;
$$;
```

These are the important parts:

| Part | What it means |
| ---- | ------------- |
| `@STAFF_S3_EXPORT_STAGE/staff_data.csv` | Write the output **with this exact file name** |
| `HEADER = TRUE` | Write the column names as the first row |
| `SINGLE = TRUE` | Create **one** file instead of many part files |
| `OVERWRITE = TRUE` | Replace the file if it already exists |

### 💡 Why is the filename written explicitly?

Because the target path ends with a name, not just a folder:

```text
@STAFF_S3_EXPORT_STAGE/staff_data.csv
                       ^^^^^^^^^^^^^^^
                       exact file name
```

So you always know the file name and type. You do not get a random part-file name.

### 🚨 Do NOT run `CALL` here

```sql
-- CALL EXPORT_STAFF_TO_S3();
```

Lambda runs the procedure:

```python
cursor.execute("CALL EXPORT_STAFF_TO_S3()")
```

---

## 🐍 Step 16 — Create the Lambda Function

| Setting | Value |
| ------- | ----- |
| Function name | `snowflake-s3-export-lambda` |
| Runtime | Python 3.12 |
| Handler (the function AWS calls first) | `lambda_function.lambda_handler` |
| Execution role | `SnowflakeS3ExportPracticeRole` |

Code: [lambda_function.py](lambda_function.py)

> ⚠️ **The function AWS calls first matters.** The file must be called `lambda_function.py`. It must also contain `def lambda_handler(event, context):`. If not, Lambda cannot find your function.

> ✅ Do **not** select `SnowflakeS3ExportSnowflakeRole` here. That role belongs to Snowflake, not Lambda.

### 📦 Snowflake connector layer

The normal Python setup does **not** include the Snowflake connector. Attach a layer that adds it. The code needs it:

```python
import snowflake.connector
```

```text
Lambda
 │
 ├── lambda_function.py
 │
 └── Snowflake Connector Layer
          │
          └── snowflake.connector
```

### 🔐 Password

```python
password="<YOUR_SNOWFLAKE_PASSWORD>"
```

> ⚠️ This placeholder is on purpose. **Never save a real Snowflake password in the code.** For real work, keep it in AWS Secrets Manager and read it when the code runs.

---

## ▶️ Step 17 — What Happens When You Click Test

```text
1. You click TEST
        ↓
2. lambda_handler() starts and logs the request ID
        ↓
3. Lambda connects to Snowflake with the Python connector
        ↓
4. Lambda executes:  CALL EXPORT_STAFF_TO_S3()
        ↓
5. The stored procedure runs COPY INTO @STAFF_S3_EXPORT_STAGE/staff_data.csv
        ↓
6. Snowflake assumes SnowflakeS3ExportSnowflakeRole via the storage integration
        ↓
7. Snowflake writes staff_data.csv to S3
        ↓
8. Lambda runs LIST @STAFF_S3_EXPORT_STAGE and prints the file name, size and MD5
        ↓
9. Lambda closes the cursor and connection
        ↓
10. All print() output appears in CloudWatch Logs
```

Expected CloudWatch output:

```text
======================================================================
SNOWFLAKE -> S3 EXPORT PIPELINE
======================================================================

[1/4] Connecting to Snowflake...
      Snowflake connection : SUCCESS
      Database             : SNOWFLAKE_S3_EXPORT_PRACTICE
      Schema               : S3_EXPORT_SCHEMA
      Warehouse            : S3_EXPORT_WH

[2/4] Executing Snowflake Stored Procedure...
      Procedure            : EXPORT_STAFF_TO_S3
      Stored Procedure     : SUCCESS
      SP Result            : SUCCESS: Staff data successfully exported to S3 as staff_data.csv

[3/4] Checking the S3 export location...
      Stage                : @STAFF_S3_EXPORT_STAGE
      Files Found          : 1
      File Name            : s3://snowflake-s3-export-practice-2026/employee-export/staff_data.csv
      File Size            : 342 bytes
      MD5                  : 0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6

[4/4] PIPELINE COMPLETED SUCCESSFULLY

------------------------------------------------------------------
EXPORT SUMMARY
------------------------------------------------------------------
Source Table              : STAFF_DATA
Stored Procedure          : EXPORT_STAFF_TO_S3
Export Stage              : @STAFF_S3_EXPORT_STAGE
Export Format             : CSV
Files Generated           : 1
Execution Time            : 3.12 seconds
Final Status              : SUCCESS
------------------------------------------------------------------
```

And in S3:

```text
snowflake-s3-export-practice-2026
└── employee-export/
        └── staff_data.csv
```

---

## 📊 Roles Comparison

| Item | `SnowflakeS3ExportPracticeRole` | `SnowflakeS3ExportSnowflakeRole` |
| ---- | ------------------------------- | -------------------------------- |
| Used by | Lambda | Snowflake |
| Attached to Lambda? | ✅ YES | ❌ NO |
| What it is for | Runs the Lambda function | Snowflake → S3 access |
| `AWSLambdaBasicExecutionRole` | ✅ Yes | ❌ No |
| `AmazonS3FullAccess` | ✅ Currently attached | ✅ Yes |
| Trust principal | `lambda.amazonaws.com` | Snowflake IAM user |
| Used for CloudWatch logs | ✅ | ❌ |
| Used for S3 by the current Lambda code | ❌ Not really needed | ✅ Yes |
| Used by the storage integration | ❌ | ✅ Yes |

---

## 🗂️ Final Snowflake Objects

```text
SNOWFLAKE_S3_EXPORT_PRACTICE
│
└── S3_EXPORT_SCHEMA
    │
    ├── STAFF_DATA
    ├── STAFF_CSV_FORMAT
    ├── S3_EXPORT_INTEGRATION
    ├── STAFF_S3_EXPORT_STAGE
    └── EXPORT_STAFF_TO_S3()

S3_EXPORT_WH
```

---

## ☁️ Final AWS Objects

```text
AWS
│
├── S3
│   └── snowflake-s3-export-practice-2026
│       └── employee-export/
│           └── staff_data.csv
│
├── IAM Role
│   └── SnowflakeS3ExportPracticeRole
│       ├── AWSLambdaBasicExecutionRole
│       └── AmazonS3FullAccess
│
├── IAM Role
│   └── SnowflakeS3ExportSnowflakeRole
│       └── AmazonS3FullAccess
│
└── Lambda
    └── snowflake-s3-export-lambda
        └── Layer: Snowflake Python Connector
```

---

## 🚨 Common Errors

| Error | Why it happens | How to fix it |
| ----- | -------------- | ------------- |
| `Access Denied` on `LIST @stage` | The trust rule does not match the integration | Run `DESC INTEGRATION` again. Paste both values into the role trust rule |
| `Access Denied` even with the right trust policy | The role cannot write to the bucket | Attach `AmazonS3FullAccess` to the role |
| `Insufficient privileges to operate on integration` | The role that creates the stage has no rights on the integration | `GRANT USAGE ON INTEGRATION S3_EXPORT_INTEGRATION TO ROLE <your_role>;` |
| `Storage integration ... is not enabled` | `ENABLED = TRUE` was missed or set to false | `ALTER STORAGE INTEGRATION S3_EXPORT_INTEGRATION SET ENABLED = TRUE;` |
| `Failure using stage area. Cause: Access Denied` during `COPY INTO` | The allowed location does not include the path we write to | Add the path to `STORAGE_ALLOWED_LOCATIONS` |
| Lambda: `Unable to import module 'lambda_function'` | The file name or the first function name is wrong | File must be `lambda_function.py`, the first function must be `lambda_function.lambda_handler` |
| Lambda: `No module named 'snowflake'` | The connector layer is not attached | Attach the Snowflake connector layer |
| Lambda: `250001: Could not connect to Snowflake backend` | The account identifier is wrong, or there is no network access to Snowflake | Check `account="XLTGLZP-IZC37171"` and make sure the account is not blocked |
| Extra part files in S3 instead of one file | `SINGLE = TRUE` is missing | Recreate the procedure with `SINGLE = TRUE` |
| File has no header row | `HEADER = TRUE` is missing in `COPY INTO` | Add `HEADER = TRUE` |

---

## 🎓 What to Take Away

**Snowflake**

```text
CREATE DATABASE / SCHEMA / WAREHOUSE
CREATE TABLE / INSERT / SELECT
CREATE FILE FORMAT
CREATE STORAGE INTEGRATION   ← Snowflake → AWS trust
DESC INTEGRATION
CREATE STAGE (external)
SHOW STAGES / DESC STAGE / LIST @stage
COPY INTO @stage   ← the actual unload
CREATE PROCEDURE / CALL
SINGLE / HEADER / OVERWRITE
```

**AWS**

```text
S3 bucket + prefix
IAM role + trust policy
External ID condition
Managed policies
Lambda + handler + runtime
Lambda layers
CloudWatch Logs
```

**Integration**

```text
Lambda
   ↓ Snowflake Connector
Snowflake
   ↓ CALL
Stored Procedure
   ↓ COPY INTO
External Stage
   ↓ Storage Integration
IAM Role
   ↓
Amazon S3
```

---

## 🗣️ Interview Explanation

> "I built a pipeline that moves data from Snowflake to S3. AWS Lambda is the outside trigger — the thing that starts the job. Lambda connects to Snowflake with the Snowflake Python Connector. Then it calls a stored procedure. The procedure runs `COPY INTO` against an external stage. That stage is secured by a Snowflake **storage integration**. So no AWS keys are stored in Snowflake. Instead, Snowflake uses an AWS role for a short time, and the request carries a secret code (external ID). The data goes to Amazon S3 as one CSV file. It uses `HEADER = TRUE`, `SINGLE = TRUE` and an exact target file name. After the procedure returns, Lambda checks the file with `LIST`. It logs the file name, size and MD5 to CloudWatch. Then it returns a clear success or failure response. The design uses **two AWS roles** because the two callers are different AWS identities. Lambda uses one role for a short time. Snowflake's IAM user uses the other role for S3 access."
