# 58) Snowflake — Snowpipe Auto-Ingestion Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [input files/](input%20files/) | `first.csv` (3 rows) and `second.csv` (2 rows) |

---

## 🧠 First: What Is Snowpipe?

Snowpipe is Snowflake's **continuous/automated file ingestion mechanism**.

Normal `COPY INTO`:

```text
CSV
 ↓
Stage
 ↓
YOU run COPY INTO
 ↓
Table
```

Snowpipe:

```text
New CSV
   ↓
Stage
   ↓
Snowpipe
   ↓
Table
```

The Pipe itself contains the `COPY INTO` definition.

---

## 🧠 Snowpipe vs COPY INTO

| `COPY INTO`             | Snowpipe                                 |
| ----------------------- | ---------------------------------------- |
| Manual/batch loading    | Continuous/automated ingestion mechanism |
| You execute the command | Pipe contains the `COPY INTO`            |
| Stage → Table           | Stage → Snowpipe → Table                 |

So:

```text
COPY INTO

File
 ↓
Stage
 ↓
YOU RUN COPY INTO
 ↓
Table
```

versus:

```text
Snowpipe

File
 ↓
Stage
 ↓
Snowpipe
 ↓
Table
```

---

## ⚠️ Important: Our Snowflake-Only Practical

There are two concepts:

### 🧪 Snowflake-only practice

```text
CSV
 ↓
Internal Stage
 ↓
Snowpipe
 ↓
ALTER PIPE REFRESH
 ↓
Table
```

### 🏭 Production auto-ingestion

```text
New File
 ↓
Cloud Storage
 ↓
Event Notification
 ↓
Snowpipe
 ↓
Table
```

Production Snowpipe commonly uses an event/notification mechanism to tell Snowpipe that a new file has arrived.

Since our goal is **pure Snowflake**, we will use an **internal stage + `ALTER PIPE ... REFRESH`**.

---

## 🏗️ Complete Pipeline

```text
                  CSV FILE
                     │
                     ↓
              INTERNAL STAGE
                     │
                     ↓
                  SNOWPIPE
                     │
             ALTER PIPE REFRESH
                     │
                     ↓
               EMPLOYEE TABLE
```

---

## 🗄️ Step 1 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_SNOWPIPE_PRACTICE;

USE DATABASE SNOWFLAKE_SNOWPIPE_PRACTICE;
```

---

## 📂 Step 2 — Create the Schema

```sql
CREATE SCHEMA SNOWPIPE_SCHEMA;

USE SCHEMA SNOWPIPE_SCHEMA;
```

---

## ⚙️ Step 3 — Create the Warehouse

```sql
CREATE WAREHOUSE SNOWPIPE_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE SNOWPIPE_WH;
```

---

## 📋 Step 4 — Create the Target Table

```sql
CREATE TABLE EMPLOYEE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER,
    JOINING_DATE  DATE
);
```

Check:

```sql
DESC TABLE EMPLOYEE;
```

---

## 📄 Step 5 — Create the File Format

```sql
CREATE FILE FORMAT EMPLOYEE_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'YYYY-MM-DD';
```

Check:

```sql
DESC FILE FORMAT EMPLOYEE_CSV_FORMAT;
```

---

## 📥 Step 6 — Create the Internal Stage

```sql
CREATE STAGE EMPLOYEE_STAGE
    FILE_FORMAT = EMPLOYEE_CSV_FORMAT;
```

Check:

```sql
SHOW STAGES;
```

---

## ⚡ Step 7 — Create the Snowpipe

🔥 This is the main part.

```sql
CREATE PIPE EMPLOYEE_PIPE
AS
COPY INTO EMPLOYEE
FROM @EMPLOYEE_STAGE
FILE_FORMAT = (
    FORMAT_NAME = 'EMPLOYEE_CSV_FORMAT'
);
```

The important part is:

```sql
COPY INTO EMPLOYEE
FROM @EMPLOYEE_STAGE
```

The Pipe stores this loading definition.

---

## 🔍 Step 8 — Check the Pipe

```sql
SHOW PIPES;
```

You should see:

```text
EMPLOYEE_PIPE
```

Then:

```sql
DESC PIPE EMPLOYEE_PIPE;
```

You should see the `COPY INTO` definition.

---

## 📊 Step 9 — Check the Pipe Status

```sql
SELECT SYSTEM$PIPE_STATUS('EMPLOYEE_PIPE');
```

This gives you information about the Pipe's current state.

---

## 📝 Step 10 — Create the Input CSV

Create a file called:

```text
first.csv
```

with:

```csv
employee_id,employee_name,email,department,salary,joining_date
9001,Rahul Sharma,rahul@example.com,IT,85000,2026-09-20
9002,Priya Patil,priya@example.com,HR,62000,2026-09-21
9003,Amit Verma,amit@example.com,Finance,95000,2026-09-22
```

> 📌 This file already exists in [input files/](input%20files/) — you can upload it directly instead of typing it out.

---

## ⬆️ Step 11 — Upload the CSV to the Stage

In Snowsight:

```text
Data → Databases → SNOWFLAKE_SNOWPIPE_PRACTICE → SNOWPIPE_SCHEMA → Stages → EMPLOYEE_STAGE → Upload Files
```

Upload:

```text
first.csv
```

---

## 🔍 Step 12 — Verify the Stage

Run:

```sql
LIST @EMPLOYEE_STAGE;
```

You should see:

```text
employee_stage/first.csv
```

At this point, **don't run `COPY INTO` manually**.

That's the whole point of this practical.

---

## 🔄 Step 13 — Trigger a Snowpipe Refresh

This is the important correction.

Run:

```sql
ALTER PIPE EMPLOYEE_PIPE REFRESH;
```

This tells Snowpipe:

> Scan the stage for files that haven't been loaded and process them.

So our flow is:

```text
first.csv
   ↓
EMPLOYEE_STAGE
   ↓
ALTER PIPE EMPLOYEE_PIPE REFRESH
   ↓
EMPLOYEE_PIPE
   ↓
COPY INTO EMPLOYEE
   ↓
EMPLOYEE
```

---

## ✅ Step 14 — Check the Table

Wait a few seconds and run:

```sql
SELECT * FROM EMPLOYEE ORDER BY EMPLOYEE_ID;
```

You should get:

```text
9001 | Rahul Sharma | rahul@example.com | IT      | 85000 | 2026-09-20
9002 | Priya Patil  | priya@example.com  | HR      | 62000 | 2026-09-21
9003 | Amit Verma   | amit@example.com   | Finance | 95000 | 2026-09-22
```

Check the count:

```sql
SELECT COUNT(*) FROM EMPLOYEE;
```

Expected:

```text
3
```

---

## ➕ Step 15 — Add Another File

Now create:

```text
second.csv
```

with:

```csv
employee_id,employee_name,email,department,salary,joining_date
9004,Sneha Joshi,sneha@example.com,IT,78000,2026-09-23
9005,Vikas Kumar,vikas@example.com,Sales,58000,2026-09-24
```

Upload it to `EMPLOYEE_STAGE`.

> 📌 This file also already exists in [input files/](input%20files/).

---

## 🔍 Step 16 — Check the Stage

```sql
LIST @EMPLOYEE_STAGE;
```

Now you should have:

```text
employee_stage/first.csv
employee_stage/second.csv
```

---

## 🔄 Step 17 — Refresh Snowpipe Again

```sql
ALTER PIPE EMPLOYEE_PIPE REFRESH;
```

Snowpipe checks the stage.

Conceptually:

```text
first.csv                      second.csv
    ↓                               ↓
Already loaded                      New
    ↓                               ↓
  SKIP                             LOAD
```

---

## ✅ Step 18 — Verify Again

```sql
SELECT * FROM EMPLOYEE ORDER BY EMPLOYEE_ID;
```

Expected:

```text
9001
9002
9003
9004
9005
```

And:

```sql
SELECT COUNT(*) FROM EMPLOYEE;
```

Expected:

```text
5
```

---

## 📊 Step 19 — Check the Snowpipe Status

```sql
SELECT SYSTEM$PIPE_STATUS('EMPLOYEE_PIPE');
```

Use this when you want to investigate whether the Pipe is operating correctly.

---

## 🕘 Step 20 — Check the Load History

Use:

```sql
SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    LAST_LOAD_TIME
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'SNOWFLAKE_SNOWPIPE_PRACTICE.SNOWPIPE_SCHEMA.EMPLOYEE',
        START_TIME => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;
```

You should see your files and their load status.

For example:

```text
first.csv   | LOADED | 3
second.csv  | LOADED | 2
```

---

## 📈 Step 21 — Check the Pipe Usage History

You can also check:

```sql
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(
        DATE_RANGE_START => DATEADD(HOUR, -1, CURRENT_TIMESTAMP()),
        DATE_RANGE_END => CURRENT_TIMESTAMP()
    )
);
```

This is useful for monitoring Snowpipe usage.

---

## ⚠️ Step 22 — If You Run the Practical Again

Suppose `first.csv` is already loaded and you want to test it again.

Don't just upload another file with exactly the same name and expect it to load as a new file.

For a clean practice, use:

```text
third.csv
```

or remove the old stage files first:

```sql
REMOVE @EMPLOYEE_STAGE;
```

Then upload a new file.

---

## 🧠 The Most Important Concept

You now have three different ingestion methods in your head:

### 📁 Pipelines 50/51 — `COPY INTO`

```text
CSV
 ↓
Stage
 ↓
YOU RUN COPY INTO
 ↓
Table
```

### 📁 Pipeline 53 — Incremental File Loading

```text
New files
 ↓
Stage
 ↓
COPY INTO
 ↓
Snowflake recognizes previously loaded files
 ↓
Only new files loaded
```

### ⚡ Pipeline 58 — Snowpipe

```text
New file
 ↓
Stage
 ↓
Snowpipe
 ↓
ALTER PIPE REFRESH
 ↓
Table
```

And in a production event-driven setup:

```text
New file
 ↓
Cloud Storage
 ↓
Event Notification
 ↓
Snowpipe
 ↓
Table
```

---

## 🧠 Snowpipe vs Task

Don't confuse them.

### ⏰ Task

```text
Task
 ↓
Runs SQL
 ↓
Schedule / dependency
```

Example:

```text
Every 5 minutes
       ↓
     Task
       ↓
     MERGE
```

### ⚡ Snowpipe

```text
New file
   ↓
Snowpipe
   ↓
Load file
```

So remember:

```text
TASK
= WHEN/HOW should SQL execute?

SNOWPIPE
= How do I continuously ingest arriving files?
```

---

## 🔥 Stream + Task + Snowpipe

Eventually, these can work together:

```text
                  NEW FILE
                     ↓
                  SNOWPIPE
                     ↓
                  RAW TABLE
                     ↓
                   STREAM
                     ↓
                CHANGED ROWS
                     ↓
                    TASK
                     ↓
                   MERGE
                     ↓
                FINAL TABLE
```

That's a very useful Snowflake architecture.

But we're intentionally learning each component separately first.