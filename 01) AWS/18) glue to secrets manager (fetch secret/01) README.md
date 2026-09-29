# Glue → Secrets Manager

## Goal

This pipeline demonstrates how an AWS Glue job fetches a secret from **AWS Secrets Manager**.

The secret contains:

```
username
password
```

Secret name:

```
new_secret_2026
```

The Glue job will:

1. Fetch the secret from Secrets Manager.
2. Log the Secret Manager name.
3. Log the key names.
4. Log `Secret fetched successfully`.

The actual username and password are **never logged**.

---

## IAM Role

Create this Glue job role:

```
GlueSecretsManagerPracticeRole
```

Attach these managed policies:

```
AWSGlueConsoleFullAccess
SecretsManagerReadWrite
```

### Purpose

`AWSGlueConsoleFullAccess`

Allows the Glue job to run, and to read its own run logs.

`SecretsManagerReadWrite`

Allows the Glue job to access Secrets Manager.

> `SecretsManagerReadWrite` is suitable for this practice pipeline. In production, a more restricted custom policy with only the required `GetSecretValue` permission should be used.

> `AWSGlueConsoleFullAccess` only allows `logs:GetLogEvents` — that is **reading** logs, not **writing** them. A Glue job writes its run log with the permissions of its own role, so also attach `AWSGlueServiceRole` (or add `logs:CreateLogGroup`, `logs:CreateLogStream` and `logs:PutLogEvents` on `/aws-glue/*`). Without this the job can succeed but the log group stays empty.

> The trust policy for this role is in [trust_policy.json](trust_policy.json) — it allows only `glue.amazonaws.com` to assume the role.

---

## Secrets Manager

Create a secret in:

**AWS Console → Secrets Manager → Store a new secret**

Secret name:

```
new_secret_2026
```

Add the following keys:

```
username = admin
password = MyPassword@123
```

The secret will contain:

```
{
    "username": "admin",
    "password": "MyPassword@123"
}
```

The Lambda pipeline reads this same secret, so the two pipelines can share one secret.

---

## Why Is This Pipeline Important?

When a Glue job needs to connect to a database, API, or any other external service, we usually need credentials such as:

```
Username
Password
API Key
Access Token
```

We should **not hardcode these credentials inside the Glue job code**.

For example, we should never write:

```
username = "admin"
password = "MyPassword@123"
```

If these credentials are hardcoded, they can be exposed through the Glue job script, GitHub, the S3 script location, logs, or other places where the code may be accessed.

Instead, we store the credentials securely in **AWS Secrets Manager**.

The Glue job then retrieves the secret at runtime using its **IAM job role**.

This keeps sensitive credentials outside the application code and makes them easier to manage or rotate when required.

The same approach can be used when a Glue job needs to connect to:

```
Database
RDS
Redshift
External APIs
Third-party services
```

The general pattern is:

```
Secrets Manager
       |
       | Fetch credentials
       v
   Glue Job
       |
       | Use credentials
       v
 Database / API / Service
```

---

## Architecture

```
AWS Secrets Manager
        |
        | get_secret_value()
        v
    Glue Job
        |
        v
  CloudWatch Logs
```

---

## Glue Job

Glue job name:

```
glue-secrets-manager-practice
```

Job type and version:

```
Spark
Glue 4.0 (Python 3)
```

The Glue code uses:

```
secrets_manager.get_secret_value()
```

to fetch the secret.

The secret is converted from JSON into a Python dictionary, and only the **key names** are logged.

The actual values are never logged.

The script logs through a Python logger named `secret-manager-pipeline`, so every line carries a time stamp and a level — `INFO` for the normal lines, `ERROR` for the failure lines.

A Glue script has no handler and no return value, so the failure path logs the error and then **raises** it. That raised exception is what marks the job run as **FAILED**.

The code ships with a placeholder secret name:

```
secret_name = "YOUR SECRET MANAGER NAME"
```

Replace it with `new_secret_2026`. The name in the code and the name in the console must match exactly, or the job fails with `ResourceNotFoundException`.

---

## Expected Output

```
2026-09-29 10:15:22,101 INFO ===================================
2026-09-29 10:15:22,101 INFO Glue Job Started
2026-09-29 10:15:22,101 INFO ===================================
2026-09-29 10:15:22,102 INFO -----------------------------------
2026-09-29 10:15:22,102 INFO Secret Manager Pipeline
2026-09-29 10:15:22,102 INFO -----------------------------------
2026-09-29 10:15:22,102 INFO Secret Name : new_secret_2026
2026-09-29 10:15:22,102 INFO -----------------------------------
2026-09-29 10:15:22,102 INFO Keys inside Secret:
2026-09-29 10:15:22,102 INFO -----------------------------------
2026-09-29 10:15:22,102 INFO - username
2026-09-29 10:15:22,102 INFO - password
2026-09-29 10:15:22,102 INFO -----------------------------------
2026-09-29 10:15:22,102 INFO Secret fetched successfully
2026-09-29 10:15:22,102 INFO -----------------------------------
2026-09-29 10:15:22,103 INFO ===================================
2026-09-29 10:15:22,103 INFO Glue Job Completed Successfully
2026-09-29 10:15:22,103 INFO ===================================
```

The date, the time and the level are added by the logger — you never type them.

The log group is `/aws-glue/jobs/output`.

The following should **never appear in CloudWatch**:

```
admin
MyPassword@123
```

---

## Testing

1. Create the secret `new_secret_2026`.
2. Add `username` and `password`.
3. Create the IAM role.
4. Attach the required policies.
5. Create the Glue job.
6. Attach `GlueSecretsManagerPracticeRole`.
7. Add the Glue code.
8. Run the job.
9. Check the CloudWatch logs in `/aws-glue/jobs/output`.

---

## Important

Never hardcode passwords, database credentials, API keys, or tokens inside a Glue job script.

Use:

```
Secrets Manager → Glue Job → Database/API
```

instead of:

```
Hardcoded Password → Glue Job → Database/API
```

This is a common and important pattern when building secure AWS data pipelines.
