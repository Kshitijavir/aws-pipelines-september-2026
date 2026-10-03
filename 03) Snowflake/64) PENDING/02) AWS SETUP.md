# ⚙️ AWS Setup — 64) S3 → EventBridge → Step Functions → Snowflake SP1 → SP2 Pipeline

[01) README.md](01%29%20README.md) explains **what the pipeline does**. This file explains **how to build it**.

Everything below lives in **us-east-1**, in AWS account **772346609795**.

---

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [01) README.md](01%29%20README.md) | The pipeline design: what happens at every step |
| [snowflake.sql](snowflake.sql) | Database, schema, warehouse, storage integration, stage, file format, staging table, dimensions, fact table, both audit tables and SP1 + SP2 |
| [lambda1_start_sp1.py](lambda1_start_sp1.py) | Lambda 1 — starts SP1 asynchronously, returns the Snowflake Query ID |
| [lambda2_check_sp1.py](lambda2_check_sp1.py) | Lambda 2 — checks that Query ID and reads `AUDIT_TABLE_1` |
| [lambda3_run_sp2.py](lambda3_run_sp2.py) | Lambda 3 — runs SP2 and reads `AUDIT_TABLE_2` |
| [email_lambda.py](email_lambda.py) | Email Lambda — sends the SUCCESS / FAILURE email through SES |
| [email.html](email.html), [email.css](email.css) | The HTML email template Lambda injects the CSS into |
| [step_functions_state_machine.json](step_functions_state_machine.json) | The Step Functions definition, including the 3 minute Wait |
| [eventbridge_s3_rule.json](eventbridge_s3_rule.json) | The EventBridge rule that matches a CSV arriving in `raw/` |
| [trust_policy_aws_role.json](trust_policy_aws_role.json) | Trust policy for the AWS services role (`lambda.amazonaws.com`, `states.amazonaws.com`) |
| [trust_policy_snowflake_role.json](trust_policy_snowflake_role.json) | Trust policy for the Snowflake role (Snowflake's IAM user + external ID) |
| [sample_orders.csv](sample_orders.csv) | A ready-made file to upload to `raw/` for a test run |
| [test_event_lambda1.json](test_event_lambda1.json) | Test event for Lambda 1 — looks like a real EventBridge S3 event |
| [test_event_lambda2.json](test_event_lambda2.json) | Test event for Lambda 2 — a Query ID |
| [test_event_lambda3.json](test_event_lambda3.json) | Test event for Lambda 3 — what Lambda 2 returns |
| [test_email_success.json](test_email_success.json) | Test event for the Email Lambda — a successful run |
| [test_email_failure.json](test_email_failure.json) | Test event for the Email Lambda — a failed run |
| [cleanup.md](cleanup.md) | Removes every Snowflake and AWS object again |

---

## 🔑 The Two Roles

This pipeline uses **two** IAM roles, and they do different jobs.

| Role | Trusted by | What it is for |
| ---- | ---------- | -------------- |
| `SnowflakeStepFunctionsPracticeRole` | `lambda.amazonaws.com` and `states.amazonaws.com` | **The AWS side.** All four Lambdas run as this role, and it is also the Step Functions execution role. It carries the managed policies |
| `SnowflakeStepFunctionsSnowflakeRole` | Snowflake's IAM user (`arn:aws:iam::...:user/...`) with an external ID | **The Snowflake side.** Snowflake assumes this role to read the CSV from S3. It is what makes the storage integration work |

> 💡 The Snowflake role exists so that **no AWS keys are ever stored in Snowflake**. Snowflake borrows the role for a short time instead, and the trust policy pins the exchange to one IAM user and one external ID.

---

## 🥇 STEP 1 — Create the S3 Bucket

**Go to:** S3 Console → **Create bucket**

| Setting | Value |
| ------- | ----- |
| Bucket name | `snowflake-step-functions-pipeline-2026` |
| Region | us-east-1 |

Then create the folder the files land in:

```text
snowflake-step-functions-pipeline-2026
└── raw/                 <-- every CSV that arrives here starts a run
```

### Turn on EventBridge notifications

**S3 bucket → Properties → Event notifications → Amazon EventBridge → Edit → On**

> ⚠️ Without this switch, S3 never tells EventBridge that a file arrived, and the pipeline never starts. The S3 event does **not** need any other notification configuration — EventBridge gets them all.

---

## 🥈 STEP 2 — Create the Snowflake Role

**Go to:** IAM → **Roles** → **Create role** → **AWS account** → **Another AWS account**

| Setting | Value |
| ------- | ----- |
| Role name | `SnowflakeStepFunctionsSnowflakeRole` |
| Trusted entity | Another AWS account, with the external ID that Snowflake gives you in step 4 |

Paste [trust_policy_snowflake_role.json](trust_policy_snowflake_role.json) as the trust policy once you have the two values from `DESC INTEGRATION`.

### Permissions for this role

The file travels **S3 → Snowflake**, so this role only needs to **read**:

| Managed policy | Why |
| -------------- | --- |
| `AmazonS3ReadOnlyAccess` | Lets Snowflake read the CSV from the bucket |

> 💡 For production, replace that with an inline policy limited to `s3:GetObject` and `s3:ListBucket` on `arn:aws:s3:::snowflake-step-functions-pipeline-2026/raw/*`.

---

## 🥉 STEP 3 — Run the Snowflake SQL

Open a Snowflake worksheet and run [snowflake.sql](snowflake.sql) from top to bottom.

It creates the database, the schema, the warehouse, the file format, the storage integration, the external stage, `STAGING_ORDERS`, `DIM_CUSTOMER`, `DIM_PRODUCT`, `FACT_SALES`, `AUDIT_TABLE_1`, `AUDIT_TABLE_2`, `SP1_LOAD_STAGING` and `SP2_LOAD_STAR_SCHEMA`.

At the end, run:

```sql
DESC INTEGRATION S3_PIPELINE_INTEGRATION;
```

---

## 🏅 STEP 4 — Connect the Two Sides

`DESC INTEGRATION S3_PIPELINE_INTEGRATION` returns two values. Copy them into the trust policy of `SnowflakeStepFunctionsSnowflakeRole`:

| From the DESC output | Goes into |
| -------------------- | --------- |
| `STORAGE_AWS_IAM_USER_ARN` | the `"AWS"` principal in [trust_policy_snowflake_role.json](trust_policy_snowflake_role.json) |
| `STORAGE_AWS_EXTERNAL_ID` | the `sts:ExternalId` condition in the same file |

Then prove it works:

```sql
LIST @RAW_S3_PIPELINE_STAGE;
```

> ✅ `0 rows` is fine. What matters is that you do **not** get `Access Denied`. If you do, the two values are not pasted correctly.

---

## 🏆 STEP 5 — Create the AWS Services Role

**Go to:** IAM → **Roles** → **Create role** → **AWS service** → **Lambda**

| Setting | Value |
| ------- | ----- |
| Role name | `SnowflakeStepFunctionsPracticeRole` |

Its trust policy is [trust_policy_aws_role.json](trust_policy_aws_role.json). It trusts `lambda.amazonaws.com` **and** `states.amazonaws.com`, because the same role is used by the four Lambdas **and** by the state machine.

### Managed policies to attach

| Managed policy | Why it is needed |
| -------------- | ---------------- |
| `AWSLambdaBasicExecutionRole` | Lets every Lambda write to CloudWatch Logs |
| `AWSLambdaRole` | Lets the state machine invoke the four Lambda functions |
| `AmazonSESFullAccess` | Lets the Email Lambda send through SES |
| `AmazonS3ReadOnlyAccess` | Lets you re-read the raw file when troubleshooting a run |

---

## 📧 STEP 6 — Verify the Sender and the Recipients in SES

**Go to:** SES Console (us-east-1) → **Configuration → Identities → Create identity**

| What | Value |
| ---- | ----- |
| Sender | `no-reply@kshitijaws.site` — verify the **domain** `kshitijaws.site` |
| Recipients | Every address in `RECIPIENTS` inside [email_lambda.py](email_lambda.py) |

> ⚠️ **SES sandbox rule:** while the account is in the sandbox, **both the sender and every recipient must be verified**. The domain verification gives SES the DKIM records it needs, which also keeps the mail out of spam.
>
> 💡 If you change `RECIPIENTS`, you must verify the new addresses too.

---

## 🚀 STEP 7 — Create the Four Lambda Functions

All four use **Python 3.12**. Three of them need the Snowflake connector; the Email Lambda does not.

| Lambda function name | Handler | Code file | Timeout | Notes |
| -------------------- | ------- | --------- | ------- | ----- |
| `snowflake-sp1-start-lambda` | `lambda1_start_sp1.lambda_handler` | [lambda1_start_sp1.py](lambda1_start_sp1.py) | 1 min | Needs the **Snowflake connector layer** |
| `snowflake-sp1-status-lambda` | `lambda2_check_sp1.lambda_handler` | [lambda2_check_sp1.py](lambda2_check_sp1.py) | 1 min | Needs the **Snowflake connector layer** |
| `snowflake-sp2-run-lambda` | `lambda3_run_sp2.lambda_handler` | [lambda3_run_sp2.py](lambda3_run_sp2.py) | **5 min** | Needs the **Snowflake connector layer**. It waits for SP2 |
| `snowflake-pipeline-email-lambda` | `email_lambda.lambda_handler` | [email_lambda.py](email_lambda.py) | 1 min | No layer. `email.html` and `email.css` must be in the same deployment package |

| Setting | Value |
| ------- | ----- |
| Runtime | Python 3.12 |
| Execution role | `SnowflakeStepFunctionsPracticeRole` |
| Layer (first three) | Snowflake Python Connector layer |

> 🔐 Replace `<YOUR_SNOWFLAKE_PASSWORD>` in the three Snowflake files before you upload them. For real work, read it from Secrets Manager or an environment variable instead of a literal.
>
> ⚠️ `email.html` and `email.css` are loaded from the folder the handler lives in, so upload them together — a zip, or the same `os.path.dirname(__file__)` layout you used in the SES project.

---

## 🔁 STEP 8 — Create the State Machine

**Go to:** Step Functions → **Create state machine** → **Blank**

| Setting | Value |
| ------- | ----- |
| Name | `snowflake-pipeline-state-machine` |
| Type | Standard |
| Permissions | **Choose an existing role** → `SnowflakeStepFunctionsPracticeRole` |

Paste the contents of [step_functions_state_machine.json](step_functions_state_machine.json) into the definition, then save.

### What the definition does

```text
StartSP1          -> Lambda 1 starts SP1 (async) and returns the Query ID
WasSP1Started     -> body.status SUBMITTED -> WaitForSP1
                     anything else          -> SendFailureEmail
WaitForSP1        -> Wait 180 seconds
CheckSP1Status    -> Lambda 2 checks the Query ID and AUDIT_TABLE_1
IsSP1Finished     -> sp1_status SUCCESS -> RunSP2
                     sp1_status FAILURE -> SendFailureEmail
                     anything else       -> back to WaitForSP1
RunSP2            -> Lambda 3 runs SP2 and waits for it
IsSP2Finished     -> sp2_status SUCCESS -> SendSuccessEmail
                     anything else       -> SendFailureEmail
SendSuccessEmail  -> SES SUCCESS email, then End
SendFailureEmail  -> SES FAILURE email, then End
```

> 💡 **Why the loop is safe to leave open:** if SP1 is still running, the state machine keeps waiting 3 minutes and checking. That is exactly what the design calls for. If you prefer a ceiling, add an attempt counter to the state and a `Choice` that goes to `SendFailureEmail` after, say, 20 checks (one hour).
>
> 💡 Both email states send the whole state as `detail.$`, so the Email Lambda can describe the run whether it failed in SP1, in SP2, or in a Lambda itself.

---

## 📨 STEP 9 — Create the EventBridge Rule

**Go to:** EventBridge → **Rules** → **Create rule**

| Setting | Value |
| ------- | ----- |
| Name | `snowflake-pipeline-file-arrival-rule` |
| Event bus | default |
| Rule type | Rule with an event pattern |
| Event source | AWS events or EventBridge partner events |

Paste the event pattern and target from [eventbridge_s3_rule.json](eventbridge_s3_rule.json):

| Setting | Value |
| ------- | ----- |
| Event pattern | `source = aws.s3`, `detail-type = Object Created`, bucket `snowflake-step-functions-pipeline-2026`, key prefix `raw/`, key suffix `.csv` |
| Target | the Step Functions state machine `snowflake-pipeline-state-machine` |
| Execution role | `SnowflakeStepFunctionsPracticeRole` |

---

## ✅ STEP 10 — Test the Pipeline End to End

```text
1. Upload sample_orders.csv to  s3://snowflake-step-functions-pipeline-2026/raw/
   (rename it if you like, for example orders_2026_10_03.csv — it must keep
    the .csv extension and land under raw/)

2. EventBridge matches the file and starts snowflake-pipeline-state-machine

3. Watch the execution:
     StartSP1 -> Wait 3 minutes -> CheckSP1Status -> RunSP2 -> SendSuccessEmail

4. Check Snowflake:
     SELECT * FROM AUDIT_TABLE_1 ORDER BY RUN_ID DESC;
     SELECT * FROM AUDIT_TABLE_2 ORDER BY RUN_ID DESC;
     SELECT * FROM FACT_SALES;

5. Check the inbox for the SUCCESS email
   (look in Spam the first time)
```

To test a **failure**, upload a CSV whose columns do not match `STAGING_ORDERS`, or point Lambda 1 at a file name that does not exist. SP1 records the failure in `AUDIT_TABLE_1`, Lambda 2 reports `FAILURE`, and the pipeline sends the failure email instead of running SP2.

You can also test the pieces on their own, before wiring EventBridge up:

| Function | Test event |
| -------- | ---------- |
| `snowflake-sp1-start-lambda` | [test_event_lambda1.json](test_event_lambda1.json) |
| `snowflake-sp1-status-lambda` | [test_event_lambda2.json](test_event_lambda2.json) |
| `snowflake-sp2-run-lambda` | [test_event_lambda3.json](test_event_lambda3.json) |
| `snowflake-pipeline-email-lambda` | [test_email_success.json](test_email_success.json), [test_email_failure.json](test_email_failure.json) |

---

## 🚨 Common Problems

| Symptom | Why it happens | How to fix it |
| ------- | -------------- | ------------- |
| Uploading a file does nothing | S3 is not sending events to EventBridge | Bucket → Properties → Event notifications → Amazon EventBridge → On |
| No email at all, run succeeded | SES rejected the send | Verify the sender domain **and** every recipient in us-east-1 |
| No email, and the run failed at `SendFailureEmail` | The Email Lambda cannot read the templates | Upload `email.html` and `email.css` beside `email_lambda.py` in the deployment package |
| `Access Denied` on `LIST @RAW_S3_PIPELINE_STAGE` | The trust policy does not match the integration | Run `DESC INTEGRATION` again and paste both values into the Snowflake role's trust policy |
| `Failure using stage area. Cause: Access Denied` on the COPY | The Snowflake role cannot read the bucket | Attach `AmazonS3ReadOnlyAccess` to `SnowflakeStepFunctionsSnowflakeRole` |
| SP1 reports `FAILURE` but the CALL looks fine | SP1 caught its own error and wrote it to `AUDIT_TABLE_1` | Read `MESSAGE` in `AUDIT_TABLE_1`. That is where the real error text is |
| The state machine loops forever on `WaitForSP1` | SP1 never wrote an audit row, so the check keeps saying RUNNING | Look at `AUDIT_TABLE_1` and the SP1 query in Snowflake's Query History, then add an attempt ceiling as described in step 8 |
| Email Lambda: `Unable to import module` | The handler name does not match the file | Handler must be `email_lambda.lambda_handler`, and the file must be `email_lambda.py` |
| Lambda: `No module named 'snowflake'` | The connector layer is not attached | Attach the Snowflake connector layer to Lambdas 1, 2 and 3 |
| Lambda 3 times out | SP2 ran longer than the Lambda timeout | Raise the timeout of `snowflake-sp2-run-lambda` to 5 minutes or more |
| `250001: Could not connect to Snowflake backend` | Wrong account identifier, or no network access | Check `account="XLTGLZP-IZC37171"` in the Lambda files |
| SP2 succeeds but `FACT_SALES` is empty | `STAGING_ORDERS` was empty, so SP2 stopped early | This is reported as a failure on purpose. Check that `AUDIT_TABLE_1` shows rows loaded |

---

## 🎓 What Each Piece Teaches

| Piece | The idea behind it |
| ----- | ------------------ |
| S3 → EventBridge → Step Functions | Event-driven start, with no polling and no cron |
| Lambda 1 + `execute_async` | Starting a long Snowflake job without holding the Lambda open |
| Snowflake Query ID | The handle that lets a *later* Lambda ask how the job went |
| `QUERY_HISTORY_BY_USER` | Reading another session's query status from the same user |
| Wait 3 minutes + loop | Orchestrating a job that takes longer than one Lambda call |
| `AUDIT_TABLE_1` / `AUDIT_TABLE_2` | Letting each procedure record its own result, so a failure inside a procedure is not lost |
| Two IAM roles | One role for the AWS services, one role for Snowflake — and still no AWS keys stored in Snowflake |
| SES email at the end | Turning a technical run into a notification a person can read |
