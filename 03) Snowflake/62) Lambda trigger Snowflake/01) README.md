# 62) Snowflake — Lambda Trigger → Stored Procedure → Internal Stage → CSV

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [lambda_function.py](lambda_function.py) | The function AWS calls first. It connects to Snowflake, runs the saved procedure, checks the landing spot, and writes logs to CloudWatch |
| [snowflake.sql](snowflake.sql) | All the Snowflake objects — database, schema, warehouse, table, file format, landing spot and saved procedure |
| [trust_policy.json](trust_policy.json) | IAM trust policy — a role is a set of permissions that AWS gives to something that needs to do work. This file lets `lambda.amazonaws.com` use the role |

## 🎯 Goal

> 📌 **Use AWS Lambda to start the job. Lambda calls a saved list of SQL steps inside Snowflake. This is called a stored procedure. You run it with one command. The procedure exports data from a Snowflake table into a landing spot for files inside Snowflake. The files are CSV. Lambda then checks the job and writes a clear log to CloudWatch. CloudWatch is where AWS keeps the log of what your code printed.**

---

## 🧭 1. The Complete Picture

Our pipeline is this:

```text
                    AWS
                     │
                     ▼
             ┌───────────────┐
             │ AWS Lambda    │
             │               │
             │ Python        │
             └───────┬───────┘
                     │
                     │ CALL EXPORT_EMPLOYEE_DATA()
                     │
                     ▼
             ┌───────────────────┐
             │     Snowflake     │
             │                   │
             │  Stored Procedure │
             └─────────┬─────────┘
                       │
                       │ COPY INTO
                       ▼
              ┌─────────────────┐
              │ Internal Stage  │
              │                 │
              │ @EMPLOYEE_      │
              │ EXPORT_STAGE    │
              └────────┬────────┘
                       │
                       ▼
                    CSV File
                       │
                       │
             Lambda checks stage
                       │
                       ▼
               CloudWatch Logs
```

---

## 💡 2. First Understand the Business Idea

Imagine your company has a data warehouse.

Snowflake contains:

```text
EMPLOYEE_DATA
```

with:

```text
EMPLOYEE_ID
EMPLOYEE_NAME
DEPARTMENT
CITY
SALARY
```

For example:

```text
101 | Kshitij | Data Engineering | Pune       | 1200000
102 | Rahul   | AWS Engineering  | Mumbai     | 1000000
103 | Amit    | Data Analytics    | Bangalore  | 900000
104 | Sneha   | Data Engineering | Pune       | 1100000
105 | Priya   | Cloud Engineering| Hyderabad  | 1050000
```

Now imagine another process needs this data as a **CSV file**.

Instead of going into Snowflake by hand and running:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA;
```

we want AWS Lambda to start that job.

So:

```text
Lambda
   ↓
"Snowflake, please export this data."
```

Snowflake does the real export.

---

## ⚡ 3. Why Do We Use Lambda?

Lambda is the thing outside Snowflake that starts the job.

Lambda does not need to know how to export the data.

It only says:

```sql
CALL EXPORT_EMPLOYEE_DATA();
```

Think of Lambda as a person pressing a button:

```text
              Lambda
                 │
                 │ "Run the export"
                 ▼
        Snowflake Stored Procedure
                 │
                 │ "Okay, I'll handle it"
                 ▼
             Data Export
```

This is an important idea in data engineering.

### 🧩 The Three Roles

- **Lambda** = the thing that starts the job
- **Snowflake SP** = the work done inside the database
- **Snowflake Stage** = where the exported file lands

---

## 📦 4. Why Use a Stored Procedure?

Instead of putting this SQL directly into Lambda:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA
...
```

we keep the steps inside Snowflake.

Our procedure is:

```sql
CREATE OR REPLACE PROCEDURE EXPORT_EMPLOYEE_DATA()
```

and inside it:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA
FILE_FORMAT = (FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT')
OVERWRITE = TRUE;
```

So Lambda only knows one line:

```sql
CALL EXPORT_EMPLOYEE_DATA();
```

This keeps the two jobs apart.

```text
Lambda
  │
  │ Trigger
  ▼
Stored Procedure
  │
  │ Business/Data logic
  ▼
COPY INTO
  │
  ▼
Stage
```

---

## 🗄️ 5. What Is the Snowflake Table?

Our source is:

```text
EMPLOYEE_DATA
```

This is where the data lives now.

Think:

```text
EMPLOYEE_DATA
       │
       │ SELECT
       ▼
   5 employee records
```

This is our **source**.

---

## 📄 6. What Is the File Format?

We created:

```sql
CREATE FILE FORMAT EMPLOYEE_CSV_FORMAT
TYPE = 'CSV'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1
COMPRESSION = 'NONE';
```

This tells Snowflake:

> "When you create the exported file, create it as CSV and follow these formatting rules."

For example:

```text
EMPLOYEE_ID,EMPLOYEE_NAME,DEPARTMENT,CITY,SALARY
101,Kshitij,Data Engineering,Pune,1200000
102,Rahul,AWS Engineering,Mumbai,1000000
103,Amit,Data Analytics,Bangalore,900000
```

The file format controls **how the data looks inside the file**.

---

## 🪣 7. What Is the Snowflake Stage?

This part is very important.

We created:

```sql
CREATE STAGE EMPLOYEE_EXPORT_STAGE
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;
```

The stage is a storage place that Snowflake manages.

We use an **internal stage**. This is a landing spot for files inside Snowflake.

So conceptually:

```text
Snowflake
│
├── Tables
│
│   └── EMPLOYEE_DATA
│
└── Internal Stage
    │
    └── EMPLOYEE_EXPORT_STAGE
          │
          └── CSV
```

The stage is where the exported file goes.

---

## 📤 8. What Does `COPY INTO` Actually Do?

This is the main step of the pipeline.

We have:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA
FILE_FORMAT = (FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT')
OVERWRITE = TRUE;
```

Read it from left to right:

### 🔹 `FROM`

```sql
FROM EMPLOYEE_DATA
```

means:

> Take data from this table.

### 🔹 `COPY INTO`

means:

> Copy that data into a file.

### 🔹 `@EMPLOYEE_EXPORT_STAGE`

means:

> Put the new file into this Snowflake stage.

### 🔹 `FILE_FORMAT`

means:

> Generate the file using our CSV formatting rules.

So:

```text
EMPLOYEE_DATA
     │
     │ COPY INTO
     ▼
EMPLOYEE_EXPORT_STAGE
     │
     ▼
employee_data_....csv
```

---

## 🐍 9. What Exactly Is Lambda Doing?

Lambda does a few steps.

### 🔌 Step 1 — Connect

Lambda opens a connection to Snowflake using:

```python
snowflake.connector.connect(...)
```

So:

```text
AWS Lambda
     │
     │ Snowflake Python Connector
     ▼
Snowflake
```

---

### ✅ Step 2 — Check the Source Data

We execute:

```sql
SELECT COUNT(*) FROM EMPLOYEE_DATA;
```

Suppose the result is:

```text
5
```

Lambda logs:

```text
Source Table     : EMPLOYEE_DATA
Source Row Count : 5
```

Why?

Because we want a simple check.

We know:

```text
There are 5 records before export.
```

---

### 📞 Step 3 — Call the Stored Procedure

Lambda executes:

```python
cursor.execute(
    "CALL EXPORT_EMPLOYEE_DATA()"
)
```

This is the key link.

The call travels:

```text
Lambda
   │
   │ CALL
   ▼
Snowflake
   │
   ▼
EXPORT_EMPLOYEE_DATA()
```

---

## ⚙️ 10. What Happens Inside the SP?

The saved procedure runs:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA
...
```

So:

```text
EMPLOYEE_DATA
      │
      │ 5 rows
      ▼
COPY INTO
      │
      ▼
EMPLOYEE_EXPORT_STAGE
      │
      ▼
CSV file
```

The important point:

> **Lambda does not move the employee data. Snowflake does the export.**

A stored procedure is a saved list of SQL steps inside Snowflake. You run it with one command. That is the idea we practice here.

---

## 🤔 11. Why Does Lambda Call the SP Instead of Doing `COPY INTO` Directly?

This is a good interview question.

Suppose the export steps grow tomorrow:

```text
1. Validate data
2. Filter employees
3. Add processing date
4. Transform columns
5. Export CSV
6. Write audit information
7. Return status
```

You do not want all that SQL inside the Python Lambda.

Instead:

```text
Lambda
   │
   │ CALL
   ▼
Stored Procedure
   │
   ├── Validation
   ├── Transformation
   ├── Export
   ├── Audit
   └── Status
```

Lambda stays simple.

---

## 🔍 12. Why Does Lambda Check the Stage Afterwards?

After:

```sql
CALL EXPORT_EMPLOYEE_DATA();
```

Lambda executes:

```sql
LIST @EMPLOYEE_EXPORT_STAGE;
```

This asks Snowflake:

> "Show me the files in this stage right now."

For example:

```text
employee_data_0_0_0.csv
```

Then Lambda can log:

```text
Stage          : @EMPLOYEE_EXPORT_STAGE
Files Exported : 1
File Name      : employee_data_0_0_0.csv
File Size      : 342 bytes
```

So we do a simple check:

```text
SP SUCCESS
     │
     ▼
Stage checked
     │
     ▼
CSV exists
     │
     ▼
Pipeline SUCCESS
```

---

## 🎓 13. Why Is This a Useful Data Engineering Practice?

Because it uses many ideas from real work:

### ☁️ AWS

```text
Lambda
IAM
CloudWatch
```

### ❄️ Snowflake

```text
Database
Schema
Warehouse
Table
File Format
Internal Stage
Stored Procedure
COPY INTO
```

### 🔗 Integration

```text
Python
Snowflake Connector
AWS → Snowflake
```

### 📊 Monitoring

```text
Success logging
Failure logging
Row count
Execution time
Stage verification
```

That is a useful mix of skills for AWS data engineering practice.

---

## 🗣️ 14. Interview Explanation

If an interviewer asks:

> **Explain this pipeline.**

You can say:

> "I built an export pipeline in Snowflake. AWS Lambda starts the job. Lambda connects to Snowflake with the Snowflake Python Connector. Then it calls a saved procedure inside Snowflake. The procedure runs a `COPY INTO` command. It exports data from the `EMPLOYEE_DATA` table into a landing spot inside Snowflake. The file is CSV. After the procedure ends, Lambda checks the landing spot with `LIST`. It reads the file name and the status. Then it writes the log to CloudWatch. Lambda also handles errors. If the connection, the procedure, or the export fails, Lambda logs the error and returns a failed run."

That is a strong answer.

---

## 🧾 15. The Entire Pipeline in One Simple Example

Imagine we start with:

```text
EMPLOYEE_DATA

5 rows
```

Lambda starts:

```text
"Let's export employee data."
```

Lambda connects:

```text
Lambda
   ↓
Snowflake ✅
```

Lambda checks:

```text
5 rows
```

Lambda calls:

```sql
CALL EXPORT_EMPLOYEE_DATA();
```

Snowflake executes:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA;
```

Snowflake generates:

```text
employee_data_xxxxx.csv
```

inside:

```text
@EMPLOYEE_EXPORT_STAGE
```

Lambda checks:

```sql
LIST @EMPLOYEE_EXPORT_STAGE;
```

and finds:

```text
employee_data_xxxxx.csv
```

Finally CloudWatch says:

```text
======================================================================
SNOWFLAKE DATA EXPORT PIPELINE
======================================================================

Source Rows       : 5
Stored Procedure  : EXPORT_EMPLOYEE_DATA
Export Stage      : @EMPLOYEE_EXPORT_STAGE
Export Format     : CSV
Files Generated   : 1
Execution Time    : 2.41 seconds

Final Status      : SUCCESS

Snowflake SP successfully exported data to the stage.
======================================================================
```

So the **main job** is simple:

> **Lambda starts Snowflake → Snowflake does the export → the stage holds the CSV → Lambda checks it → CloudWatch keeps the result.**

And here is the most important split to remember:

| Piece | Role |
| ----- | ---- |
| **Lambda** | starts the job |
| **Stored Procedure** | the work inside Snowflake |
| **COPY INTO** | the export step |
| **Internal Stage** | where the exported file lands |
| **CloudWatch** | the record of what happened |
