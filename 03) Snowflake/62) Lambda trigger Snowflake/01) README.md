# 62) Snowflake — Lambda Trigger → Stored Procedure → Internal Stage → CSV

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [lambda_function.py](lambda_function.py) | AWS Lambda handler — connects to Snowflake, calls the stored procedure, checks the stage, logs to CloudWatch |
| [snowflake.sql](snowflake.sql) | All Snowflake objects — database, schema, warehouse, table, file format, internal stage and stored procedure |
| [trust_policy.json](trust_policy.json) | IAM trust policy — lets `lambda.amazonaws.com` assume the role |

## 🎯 Goal

> 📌 **Use AWS Lambda as an external trigger/orchestrator to call a Snowflake Stored Procedure, and let the Stored Procedure export data from a Snowflake table into a Snowflake internal stage as CSV files. Lambda then verifies the operation and writes a clear execution log to CloudWatch.**

---

## 🧭 1. The Complete Picture

Our pipeline is:

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

Imagine you have a company data warehouse.

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

Now imagine another downstream process needs this data as a **CSV file**.

Instead of manually going into Snowflake and running:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA;
```

we want AWS Lambda to trigger that process.

So:

```text
Lambda
   ↓
"Snowflake, please export this data."
```

Snowflake does the actual export.

---

## ⚡ 3. Why Do We Use Lambda?

Lambda is acting as the **external orchestrator/trigger**.

Lambda itself doesn't need to know how to export the data.

It simply says:

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

This is an important Data Engineering concept.

### 🧩 The Three Roles

- **Lambda** = orchestration / trigger
- **Snowflake SP** = database-side processing
- **Snowflake Stage** = destination for the exported file

---

## 📦 4. Why Use a Stored Procedure?

Instead of putting this SQL directly into Lambda:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA
...
```

we put the logic inside Snowflake.

Our procedure is:

```sql
CREATE OR REPLACE PROCEDURE EXPORT_EMPLOYEE_DATA()
```

and internally:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA
FILE_FORMAT = (FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT')
OVERWRITE = TRUE;
```

So Lambda only knows:

```sql
CALL EXPORT_EMPLOYEE_DATA();
```

This gives us separation of responsibilities.

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

This is where the data currently lives.

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

The file format controls **how the data is represented in the file**.

---

## 🪣 7. What Is the Snowflake Stage?

This is extremely important.

We created:

```sql
CREATE STAGE EMPLOYEE_EXPORT_STAGE
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;
```

The stage is a **Snowflake-managed storage location**.

We're using an **internal stage**.

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

The stage is where the exported file is placed.

---

## 📤 8. What Does `COPY INTO` Actually Do?

This is the heart of the pipeline.

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

> Export/copy that data into a file.

### 🔹 `@EMPLOYEE_EXPORT_STAGE`

means:

> Put the generated file into this Snowflake stage.

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

Lambda performs several steps.

### 🔌 Step 1 — Connect

Lambda establishes a connection to Snowflake using:

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

Because we want basic validation.

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

This is the key integration.

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

The SP runs:

```sql
COPY INTO @EMPLOYEE_EXPORT_STAGE
FROM EMPLOYEE_DATA
...
```

Therefore:

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

> **Lambda does not move the employee data itself. Snowflake performs the data export.**

This is why we're practicing the Stored Procedure concept.

---

## 🤔 11. Why Does Lambda Call the SP Instead of Doing `COPY INTO` Directly?

This is a good interview question.

Suppose tomorrow the export logic becomes:

```text
1. Validate data
2. Filter employees
3. Add processing date
4. Transform columns
5. Export CSV
6. Write audit information
7. Return status
```

You don't want all that SQL/business logic inside Python Lambda.

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

Lambda remains simple.

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

> "Show me the files currently present in this stage."

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

So we're doing a basic verification:

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

Because it combines several real-world concepts:

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

That's actually a very useful combination for your AWS Data Engineer practice.

---

## 🗣️ 14. Interview Explanation

If an interviewer asks:

> **Explain this pipeline.**

You can say:

> "I created a Snowflake-based export pipeline where AWS Lambda acts as the external orchestrator. Lambda connects to Snowflake using the Snowflake Python Connector and calls a Snowflake Stored Procedure. The Stored Procedure executes a `COPY INTO` command to export data from the `EMPLOYEE_DATA` table into a Snowflake internal stage in CSV format. After the procedure completes, Lambda verifies the stage using `LIST`, captures information such as the exported file and execution status, and writes structured logs to CloudWatch. Error handling is implemented in Lambda so connection, procedure, or export failures are logged and returned as a failed execution."

That's a strong explanation.

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

So the **core purpose** is simply:

> **Lambda triggers Snowflake → Snowflake performs the export → Stage stores the CSV → Lambda verifies it → CloudWatch records the result.**

And the most important architectural separation to remember is:

| Piece | Role |
| ----- | ---- |
| **Lambda** | trigger / orchestration |
| **Stored Procedure** | Snowflake-side logic |
| **COPY INTO** | export operation |
| **Internal Stage** | exported-file destination |
| **CloudWatch** | monitoring / logging |
