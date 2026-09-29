# ⚡ Lambda → Secrets Manager

## 🎯 Goal

This pipeline demonstrates how AWS Lambda fetches a secret from **AWS Secrets Manager**.

The secret contains:

```
👤 username
🔑 password
```

Secret name:

```
new_secret_2026
```

Lambda will:

1. 📥 Fetch the secret from Secrets Manager.
2. 🏷️ Print the Secret Manager name.
3. 🔑 Print the key names.
4. ✅ Print `Secret fetched successfully`.

🚫 The actual username and password are **never printed**.

---

## 🔐 IAM Role

Create this Lambda execution role:

```
LambdaSecretsManagerPracticeRole
```

Attach these managed policies:

```
AWSLambdaBasicExecutionRole
SecretsManagerReadWrite
```

### 🎯 Purpose

☁️ `AWSLambdaBasicExecutionRole`

Allows Lambda to write logs to **CloudWatch Logs**.

🔐 `SecretsManagerReadWrite`

Allows Lambda to access Secrets Manager.

> 💡 `SecretsManagerReadWrite` is suitable for this practice pipeline. In production, a more restricted custom policy with only the required `GetSecretValue` permission should be used.

> 📌 The trust policy for this role is in [trust_policy.json](trust_policy.json) — it allows only `lambda.amazonaws.com` to assume the role.

---

## 🔑 Secrets Manager

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

---

## 💡 Why Is This Pipeline Important?

When Lambda needs to connect to a database, API, or any other external service, we usually need credentials such as:

```
👤 Username
🔑 Password
🗝️ API Key
🎟️ Access Token
```

We should **not hardcode these credentials inside the Lambda code**.

❌ For example, we should never write:

```
username = "admin"
password = "MyPassword@123"
```

If these credentials are hardcoded, they can be exposed through the Lambda source code, GitHub, deployment packages, logs, or other places where the code may be accessed.

Instead, we store the credentials securely in **AWS Secrets Manager**.

Lambda then retrieves the secret at runtime using its **IAM execution role**.

This keeps sensitive credentials outside the application code and makes them easier to manage or rotate when required.

The same approach can be used when Lambda needs to connect to:

```
🗄️ Database
🛢️ RDS
📊 Redshift
🌐 External APIs
🤝 Third-party services
```

The general pattern is:

```
🔐 Secrets Manager
       |
       | Fetch credentials
       v
⚡ Lambda
       |
       | Use credentials
       v
🗄️ Database / API / Service
```

---

## 🗺️ Architecture

```
🔐 AWS Secrets Manager
        |
        | get_secret_value()
        v
⚡ Lambda
        |
        v
☁️ CloudWatch Logs
```

---

## 🧠 Lambda

Lambda function name:

```
lambda-secrets-manager-practice
```

Runtime:

```
Python 3.x
```

The Lambda code uses:

```
secrets_manager.get_secret_value()
```

to fetch the secret.

The secret is converted from JSON into a Python dictionary, and only the **key names** are printed.

The actual values are never printed.

⚠️ The code ships with a placeholder secret name:

```
secret_name = "YOUR SECRET MANAGER NAME"
```

Replace it with `new_secret_2026`. The name in the code and the name in the console must match exactly, or the function fails with `ResourceNotFoundException`.

---

## 🖨️ Expected Output

```
===================================
Secret Manager Pipeline
===================================
Secret Name : new_secret_2026
-----------------------------------
Keys inside Secret:
-----------------------------------
- username
- password
-----------------------------------
Secret fetched successfully
===================================
```

🚫 The following should **never appear in CloudWatch**:

```
admin
MyPassword@123
```

---

## 🧪 Testing

1. 🗝️ Create the secret `new_secret_2026`.
2. 👤 Add `username` and `password`.
3. 🔐 Create the IAM role.
4. 📎 Attach the required policies.
5. ⚡ Create the Lambda function.
6. 🔗 Attach `LambdaSecretsManagerPracticeRole`.
7. 📄 Add the Lambda code.
8. ▶️ Run a test event.
9. ☁️ Check the CloudWatch logs.

🧾 Test event:

```
{}
```

---

## ⚠️ Important

🚫 Never hardcode passwords, database credentials, API keys, or tokens inside Lambda code.

✅ Use:

```
Secrets Manager → Lambda → Database/API
```

❌ Instead of:

```
Hardcoded Password → Lambda → Database/API
```

💡 This is a common and important pattern when building secure AWS data pipelines and serverless applications.
