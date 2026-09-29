# 57) Snowflake — Scheduled CSV Export Using Task

## 📁 Files in This Folder

| File               | What It Is                           |
| ------------------ | ------------------------------------ |
| 📘 `README.md`     | This guide                           |
| 🧾 `snowflake.sql` | Complete SQL script for the pipeline |

---

# 🚀 What Are We Building?

In this practice, we will create a simple **Snowflake Task** that automatically exports employee data to a CSV file every **1 minute**.

The important part is not the employee data itself.

The goal is to understand:

* ⚡ What a Snowflake Task is
* ⏰ How task scheduling works
* ▶️ How to start a Task
* 🛑 How to stop a Task
* 📁 How a Task can execute `COPY INTO`
* 📝 How to generate a dynamic filename
* 📦 How to export data to an internal stage
* 📊 How to monitor Task execution
* 🔍 How to check success/failure
* 🔮 How to calculate upcoming executions
* 💡 Difference between `CREATE`, `RESUME`, and `SUSPEND`

---

# 🧠 1. First Understand the Problem

Imagine we have an `EMPLOYEE` table:

```text
EMPLOYEE
   │
   │ Employee data
   ↓
Need to export data automatically
   │
   ↓
Every 1 minute
   │
   ↓
Generate CSV file
   │
   ↓
Store CSV in Snowflake Stage
```

Without a Task, we would have to manually execute:

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE/employee.csv
FROM EMPLOYEE;
```

every time we wanted to export the data.

That is not automation.

Instead, we want Snowflake to automatically execute the SQL for us.

That is where a **Snowflake Task** comes in.

---

# ⚡ 2. What Is a Snowflake Task?

A **Snowflake Task** is used to automatically execute SQL or a stored procedure based on a schedule or dependency.

Think of a Task as a **scheduler inside Snowflake**.

For example:

```text
                 ⚡ SNOWFLAKE TASK
                        │
                        │
                 Every 1 minute
                        │
                        ↓
                Execute SQL
```

In our pipeline:

```text
EMPLOYEE TABLE
      │
      ↓
EMPLOYEE_TASK
      │
      │ Every 1 minute
      ↓
Generate CSV filename
      │
      ↓
COPY INTO
      │
      ↓
INTERNAL STAGE
```

### 🎤 Simple interview answer

> A Snowflake Task is used to automatically execute SQL or a stored procedure based on a schedule or dependency.

---

# 🎯 3. What Exactly Will This Task Do?

Our Task will perform the following steps:

```text
1. Wake up every 1 minute
          ↓
2. Generate a unique CSV filename
          ↓
3. Execute COPY INTO
          ↓
4. Read data from EMPLOYEE
          ↓
5. Write the data to the internal stage
          ↓
6. Record execution details in Task History
```

For example, the Task may generate:

```text
employee_export_20260930_012300.csv
```

and place that file in:

```text
@CUSTOMER_EXPORT_STAGE
```

---

# 🏗️ 4. Complete Architecture

The complete practice pipeline is:

```text
                📋 EMPLOYEE TABLE
                       │
                       │ 5 records
                       ↓
                ⚡ EMPLOYEE_TASK
                       │
                       │ Schedule
                       │ Every 1 minute
                       ↓
              📝 Generate Filename
                       │
                       ↓
                  COPY INTO
                       │
                       ↓
             📦 INTERNAL STAGE
                       │
                       ↓
              📄 CSV FILE
                       │
                       ↓
                📊 TASK HISTORY
                       │
              ┌────────┼────────┐
              ↓        ↓        ↓
           SUCCESS   FAILED   RUNNING
```

---

# 🚫 5. What We Are NOT Using

To keep this practice focused, we are **not** using:

* 🚫 Task chains
* 🚫 Child Tasks
* 🚫 Root Tasks
* 🚫 Streams
* 🚫 Stored Procedures
* 🚫 External stages
* 🚫 AWS services

The purpose of this practice is to understand the **basic Snowflake Task concept and scheduling**.

---

# 🗄️ Step 1 — Create the Database

First, create a database for the practice.

```sql
CREATE DATABASE SNOWFLAKE_TASK_PRACTICE;

USE DATABASE SNOWFLAKE_TASK_PRACTICE;
```

### Why?

We want all objects for this practice to be organized inside one database.

---

# 📂 Step 2 — Create the Schema

Create a schema to hold our objects.

```sql
CREATE SCHEMA TASK_SCHEMA;

USE SCHEMA TASK_SCHEMA;
```

Our structure is now:

```text
SNOWFLAKE_TASK_PRACTICE
        │
        └── TASK_SCHEMA
```

---

# ⚙️ Step 3 — Create the Warehouse

The Task needs compute to execute the SQL.

Create a small warehouse:

```sql
CREATE WAREHOUSE TASK_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE TASK_WH;
```

### 💡 Why XSMALL?

This is a very small practice workload.

We only have:

```text
1 table
5 records
1 COPY INTO operation
```

So an `XSMALL` warehouse is sufficient for this practice.

### `AUTO_SUSPEND = 60`

```text
AUTO_SUSPEND = 60
```

means the warehouse automatically suspends after **60 seconds of inactivity**.

### `AUTO_RESUME = TRUE`

```text
AUTO_RESUME = TRUE
```

means Snowflake can automatically resume the warehouse when it is needed.

---

# 📋 Step 4 — Create the Employee Table

Now create our source table.

```sql
CREATE TABLE EMPLOYEE (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);
```

The table contains:

| Column          | Description         |
| --------------- | ------------------- |
| `EMPLOYEE_ID`   | Employee ID         |
| `EMPLOYEE_NAME` | Employee name       |
| `DEPARTMENT`    | Employee department |
| `SALARY`        | Employee salary     |

Check the table:

```sql
SELECT * FROM EMPLOYEE;
```

At this point, the table is empty.

---

# ✍️ Step 5 — Insert Employee Data

Insert five records:

```sql
INSERT INTO EMPLOYEE VALUES
(1001, 'Rahul', 'IT', 85000),
(1002, 'Priya', 'HR', 65000),
(1003, 'Amit', 'Finance', 95000),
(1004, 'Sneha', 'IT', 78000),
(1005, 'Vikas', 'Sales', 55000);
```

Verify:

```sql
SELECT * FROM EMPLOYEE;
```

You should see:

```text
1001  Rahul   IT       85000
1002  Priya   HR       65000
1003  Amit    Finance  95000
1004  Sneha   IT       78000
1005  Vikas   Sales    55000
```

---

# 📄 Step 6 — Create the CSV File Format

Because we are exporting the employee data as CSV, create a CSV file format.

```sql
CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_1
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';
```

### What does this define?

It tells Snowflake how the exported file should be formatted.

For example:

```text
1001,"Rahul","IT",85000
```

The important settings are:

| Setting                              | Meaning                                 |
| ------------------------------------ | --------------------------------------- |
| `TYPE = 'CSV'`                       | File is CSV                             |
| `FIELD_DELIMITER = ','`              | Columns are separated by commas         |
| `COMPRESSION = 'NONE'`               | Don't compress the file                 |
| `FIELD_OPTIONALLY_ENCLOSED_BY = '"'` | Fields can be enclosed in double quotes |

---

# 📦 Step 7 — Create the Internal Stage

Now create an internal stage where Snowflake will place the exported CSV files.

```sql
CREATE STAGE CUSTOMER_EXPORT_STAGE
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_1;
```

Think of the Stage as a **file storage location inside Snowflake**.

Our flow is:

```text
EMPLOYEE
   │
   ↓
COPY INTO
   │
   ↓
CUSTOMER_EXPORT_STAGE
   │
   ↓
CSV FILE
```

---

# ⚡ Step 8 — Create the Snowflake Task

Now we reach the most important part.

Create the Task:

```sql
CREATE TASK EMPLOYEE_TASK
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE';

END;
```

---

# 🧩 Step 8.1 — Understand the Task Definition

Let's break this down.

### Task name

```sql
CREATE TASK EMPLOYEE_TASK
```

Creates a Task called:

```text
EMPLOYEE_TASK
```

---

### Warehouse

```sql
WAREHOUSE = TASK_WH
```

Tells the Task which warehouse to use when executing the SQL.

---

### Schedule

```sql
SCHEDULE = '1 MINUTE'
```

This means:

```text
Run the Task every 1 minute.
```

So conceptually:

```text
12:01 → Execute
12:02 → Execute
12:03 → Execute
12:04 → Execute
...
```

---

# 📝 Step 8.2 — Generate the Filename

Inside the Task we create:

```sql
FILE_NAME :=
    'employee_export_' ||
    TO_VARCHAR(
        CURRENT_TIMESTAMP(),
        'YYYYMMDD_HH24MISS'
    ) ||
    '.csv';
```

This dynamically creates a filename.

For example:

```text
employee_export_20260930_012300.csv
```

The structure is:

```text
employee_export_
       +
timestamp
       +
.csv
```

So every execution can generate a different filename.

---

# 🧠 Step 8.3 — Why Are We Using `CURRENT_TIMESTAMP()`?

We use:

```sql
CURRENT_TIMESTAMP()
```

to get the current date and time.

For example:

```text
2026-09-30 01:23:00
```

Then:

```sql
TO_VARCHAR(
    CURRENT_TIMESTAMP(),
    'YYYYMMDD_HH24MISS'
)
```

converts it into:

```text
20260930_012300
```

Therefore:

```text
employee_export_20260930_012300.csv
```

is generated.

---

# 🧩 Step 8.4 — What Does `EXECUTE IMMEDIATE` Do?

The final command is:

```sql
EXECUTE IMMEDIATE
    'COPY INTO @CUSTOMER_EXPORT_STAGE/' ||
    FILE_NAME ||
    ' FROM EMPLOYEE';
```

Because `FILE_NAME` is dynamically generated, we construct the SQL statement dynamically.

For example, Snowflake effectively builds:

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE/employee_export_20260930_012300.csv
FROM EMPLOYEE;
```

So the Task is doing:

```text
Generate filename
       ↓
Build COPY INTO statement
       ↓
Execute COPY INTO
       ↓
Export EMPLOYEE
       ↓
Create CSV in Stage
```

---

# ⏸️ Step 9 — Important: A New Task Starts Suspended

After creating the Task:

```sql
CREATE TASK EMPLOYEE_TASK
...
```

the Task does **not** immediately start executing.

A newly created Task is initially:

```text
SUSPENDED
```

Check it:

```sql
SHOW TASKS LIKE 'EMPLOYEE_TASK';
```

You should see the Task state as suspended.

---

# 🧠 10. `CREATE TASK` vs `RESUME` vs `SUSPEND`

This is one of the most important concepts to remember.

## 🧱 `CREATE TASK`

```sql
CREATE TASK EMPLOYEE_TASK
...
```

means:

> Create the Task definition.

Think:

```text
CREATE TASK
     ↓
Task exists
     ↓
SUSPENDED
```

---

## ▶️ `ALTER TASK ... RESUME`

```sql
ALTER TASK EMPLOYEE_TASK RESUME;
```

means:

> Enable the Task so Snowflake can schedule it.

Think:

```text
Task exists
     ↓
SUSPENDED
     ↓
RESUME
     ↓
Scheduler enabled
     ↓
Execute every 1 minute
```

---

## 🛑 `ALTER TASK ... SUSPEND`

```sql
ALTER TASK EMPLOYEE_TASK SUSPEND;
```

means:

> Stop future scheduled executions.

Think:

```text
Task running
     ↓
SUSPEND
     ↓
Future executions stop
```

The Task is **not deleted**.

You can start it again:

```sql
ALTER TASK EMPLOYEE_TASK RESUME;
```

---

# 🎤 Easy Interview Answer

> `CREATE TASK` creates the Task definition. `RESUME` enables Task scheduling, and `SUSPEND` stops future scheduled executions.

---

# ▶️ Step 10 — Resume the Task

Now start the scheduler:

```sql
ALTER TASK EMPLOYEE_TASK RESUME;
```

Check again:

```sql
SHOW TASKS LIKE 'EMPLOYEE_TASK';
```

The Task is now enabled for scheduling.

The flow becomes:

```text
CREATE TASK
     ↓
SUSPENDED
     ↓
RESUME
     ↓
SCHEDULE ACTIVE
     ↓
Every 1 minute
     ↓
Execute Task
```

---

# 📊 Step 11 — Understand What Happens During Execution

Once the Task starts executing:

```text
EMPLOYEE_TASK
      │
      ↓
Wait for scheduled time
      │
      ↓
Generate filename
      │
      ↓
COPY INTO
      │
      ↓
Read EMPLOYEE
      │
      ↓
Write CSV
      │
      ↓
CUSTOMER_EXPORT_STAGE
```

For example:

```text
employee_export_20260930_012300.csv
```

will be created in the stage.

You can check the stage with:

```sql
LIST @CUSTOMER_EXPORT_STAGE;
```

---

# 📊 Step 12 — Monitor Task Execution

Now we need to answer an important question:

> How do I know whether my Task actually ran successfully?

Snowflake provides:

```text
TASK_HISTORY
```

for Task execution information.

Our monitoring query will show:

* Previous executions
* Task status
* Scheduled time
* Start time
* Completion time
* Execution duration
* Error message
* Next 5 expected executions
* IST date/time

---

# 🔍 Step 13 — Task History Query

```sql
WITH TASK_HISTORY_DATA AS (

    SELECT
        NAME,
        STATE,
        SCHEDULED_TIME,
        QUERY_START_TIME,
        COMPLETED_TIME,
        ERROR_MESSAGE

    FROM TABLE(
        INFORMATION_SCHEMA.TASK_HISTORY(
            TASK_NAME => 'EMPLOYEE_TASK',
            SCHEDULED_TIME_RANGE_START =>
                DATEADD(
                    HOUR,
                    -1,
                    CURRENT_TIMESTAMP()
                )
        )
    )
),

LATEST_SCHEDULE AS (

    SELECT
        MAX(SCHEDULED_TIME) AS LAST_SCHEDULED_TIME

    FROM TASK_HISTORY_DATA
),

NEXT_5_EXECUTIONS AS (

    SELECT
        DATEADD(
            MINUTE,
            ROW_NUMBER() OVER (ORDER BY SEQ4()),
            LAST_SCHEDULED_TIME
        ) AS NEXT_SCHEDULE_TIME

    FROM LATEST_SCHEDULE,
         TABLE(GENERATOR(ROWCOUNT => 5))
)

-- ============================================================
-- Previous / Current Executions
-- ============================================================

SELECT

    NAME AS TASK_NAME,

    CASE
        WHEN STATE = 'SUCCEEDED' THEN 'SUCCESS'
        WHEN STATE = 'EXECUTING' THEN 'RUNNING'
        WHEN STATE = 'FAILED' THEN 'FAILED'
        WHEN STATE = 'SCHEDULED' THEN 'SCHEDULED'
        ELSE STATE
    END AS EXECUTION_STATUS,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            SCHEDULED_TIME
        ),
        'YYYY-MM-DD'
    ) AS EXECUTION_DATE_IST,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            SCHEDULED_TIME
        ),
        'HH12:MI:SS AM'
    ) || ' IST' AS SCHEDULED_TIME_IST,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            QUERY_START_TIME
        ),
        'HH12:MI:SS AM'
    ) || ' IST' AS START_TIME_IST,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            COMPLETED_TIME
        ),
        'HH12:MI:SS AM'
    ) || ' IST' AS COMPLETED_TIME_IST,

    DATEDIFF(
        'SECOND',
        QUERY_START_TIME,
        COMPLETED_TIME
    ) AS EXECUTION_SECONDS,

    ERROR_MESSAGE

FROM TASK_HISTORY_DATA


UNION ALL


-- ============================================================
-- Next 5 Expected Executions
-- ============================================================

SELECT

    'EMPLOYEE_TASK' AS TASK_NAME,

    'UPCOMING' AS EXECUTION_STATUS,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            NEXT_SCHEDULE_TIME
        ),
        'YYYY-MM-DD'
    ) AS EXECUTION_DATE_IST,

    TO_CHAR(
        CONVERT_TIMEZONE(
            'Asia/Kolkata',
            NEXT_SCHEDULE_TIME
        ),
        'HH12:MI:SS AM'
    ) || ' IST' AS SCHEDULED_TIME_IST,

    NULL AS START_TIME_IST,

    NULL AS COMPLETED_TIME_IST,

    NULL AS EXECUTION_SECONDS,

    NULL AS ERROR_MESSAGE

FROM NEXT_5_EXECUTIONS

ORDER BY
    SCHEDULED_TIME_IST DESC;
```

---

# 🧩 Step 13.1 — What Does `TASK_HISTORY` Give Us?

The query uses:

```sql
INFORMATION_SCHEMA.TASK_HISTORY()
```

to retrieve Task execution information.

The important columns are:

| Column               | Meaning                                |
| -------------------- | -------------------------------------- |
| `TASK_NAME`          | Name of the Task                       |
| `EXECUTION_STATUS`   | Success, failed, running, etc.         |
| `EXECUTION_DATE_IST` | Execution date in IST                  |
| `SCHEDULED_TIME_IST` | When Snowflake scheduled the execution |
| `START_TIME_IST`     | When execution actually started        |
| `COMPLETED_TIME_IST` | When execution finished                |
| `EXECUTION_SECONDS`  | Execution duration                     |
| `ERROR_MESSAGE`      | Error details if execution failed      |

---

# 🔮 Step 14 — Why Are We Showing the Next 5 Executions?

The Task is scheduled:

```sql
SCHEDULE = '1 MINUTE'
```

So we know that executions should occur approximately every minute.

The query generates the next five expected times.

For example:

```text
EMPLOYEE_TASK | UPCOMING | 01:24 AM IST
EMPLOYEE_TASK | UPCOMING | 01:25 AM IST
EMPLOYEE_TASK | UPCOMING | 01:26 AM IST
EMPLOYEE_TASK | UPCOMING | 01:27 AM IST
EMPLOYEE_TASK | UPCOMING | 01:28 AM IST
```

These are **expected schedule times calculated by our query**.

They are not historical Task executions.

That distinction is important.

---

# 📊 Step 15 — Example Monitoring Output

You may see something conceptually similar to:

```text
TASK_NAME      STATUS      SCHEDULED TIME       START TIME          COMPLETED TIME
------------------------------------------------------------------------------------
EMPLOYEE_TASK  SUCCESS     01:21:00 AM IST      01:21:01 AM IST     01:21:02 AM IST
EMPLOYEE_TASK  SUCCESS     01:20:00 AM IST      01:20:01 AM IST     01:20:02 AM IST
EMPLOYEE_TASK  SUCCESS     01:19:00 AM IST      01:19:01 AM IST     01:19:02 AM IST
EMPLOYEE_TASK  UPCOMING    01:22:00 AM IST      NULL                NULL
EMPLOYEE_TASK  UPCOMING    01:23:00 AM IST      NULL                NULL
```

The important thing is to understand:

```text
SUCCESS
   ↓
Task completed successfully

FAILED
   ↓
Task execution failed

RUNNING
   ↓
Task is currently executing

UPCOMING
   ↓
Expected future schedule calculated by our query
```

---

# 📁 Step 16 — Verify the Exported Files

After the Task has executed, check the stage:

```sql
LIST @CUSTOMER_EXPORT_STAGE;
```

You should see files similar to:

```text
employee_export_20260930_012100.csv
employee_export_20260930_012200.csv
employee_export_20260930_012300.csv
```

The filename changes because we generate it using:

```sql
CURRENT_TIMESTAMP()
```

---

# 🛑 Step 17 — Suspend the Task

When you finish practicing, stop the scheduled executions:

```sql
ALTER TASK EMPLOYEE_TASK SUSPEND;
```

Verify:

```sql
SHOW TASKS LIKE 'EMPLOYEE_TASK';
```

The Task should now be suspended.

### Why should we suspend it?

Because otherwise the Task continues to execute according to its schedule.

For a practice environment, suspending it prevents unnecessary repeated executions.

---

# 🔄 Step 18 — Resume the Task Again

Whenever you want to practice again:

```sql
ALTER TASK EMPLOYEE_TASK RESUME;
```

Then verify:

```sql
SHOW TASKS LIKE 'EMPLOYEE_TASK';
```

The scheduler is enabled again.

---

# ⏰ Step 19 — Different Task Schedules

We used:

```sql
SCHEDULE = '1 MINUTE'
```

Other interval examples include:

```sql
SCHEDULE = '5 MINUTE'
```

or:

```sql
SCHEDULE = '1 HOUR'
```

You can also use a CRON expression.

For example:

```sql
SCHEDULE = 'USING CRON 0 19 * * * UTC'
```

This represents:

```text
Every day
at 19:00 UTC
```

---

# 🧠 Step 20 — The Most Important Task Lifecycle

Remember this lifecycle:

```text
              CREATE TASK
                   │
                   ↓
              SUSPENDED
                   │
                   │ RESUME
                   ↓
          SCHEDULER ENABLED
                   │
                   ↓
          Wait for schedule
                   │
                   ↓
          Execute SQL
                   │
                   ↓
              Task runs
                   │
                   │ SUSPEND
                   ↓
          Future executions
               stop
                   │
                   │ RESUME
                   ↓
          Scheduling starts
              again
```

This is the core concept you should remember.

---

# 🧠 Step 21 — Task vs Stream

This is another important Snowflake interview concept.

## 🌊 Stream

A Stream answers:

> **What changed?**

```text
SOURCE TABLE
     ↓
   STREAM
     ↓
INSERT / UPDATE / DELETE changes
```

A Stream tracks changes made to table data.

---

## ⏰ Task

A Task answers:

> **When should something run?**

```text
TASK
 ↓
Schedule
 ↓
Execute SQL
```

A Task automatically executes SQL or a stored procedure according to its schedule or dependency.

---

# 🔗 Task + Stream

In real data pipelines, they can be combined:

```text
             SOURCE TABLE
                  │
                  ↓
               STREAM
                  │
            "What changed?"
                  │
                  ↓
                TASK
                  │
            "When to process?"
                  │
                  ↓
              TARGET
```

For example:

```text
EMPLOYEE
    ↓
EMPLOYEE_STREAM
    ↓
EMPLOYEE_TASK
    ↓
TARGET_TABLE
```

But we are **not using a Stream in this practice**.

We are learning Tasks first.

---

# 🎯 Step 22 — What You Should Understand After This Practice

After completing this pipeline, you should be comfortable explaining:

### 1. What is a Task?

```text
Automatic SQL execution
based on schedule/dependency
```

### 2. Why do we use a Task?

```text
To automate repetitive SQL execution.
```

### 3. What does `CREATE TASK` do?

```text
Creates the Task definition.
```

### 4. What does `RESUME` do?

```text
Enables Task scheduling.
```

### 5. What does `SUSPEND` do?

```text
Stops future scheduled executions.
```

### 6. Where do we monitor executions?

```text
TASK_HISTORY
```

### 7. What does a Stream do?

```text
Tracks changes in table data.
```

### 8. What does a Task do?

```text
Schedules/executes processing.
```

---

# 🎤 Interview Questions

## Q1. What is a Snowflake Task?

> A Snowflake Task is used to automatically execute SQL or a stored procedure based on a schedule or dependency.

---

## Q2. Does creating a Task automatically start it?

> No. A newly created Task is initially suspended. We use `ALTER TASK ... RESUME` to enable scheduling.

---

## Q3. How do you stop a Task?

```sql
ALTER TASK EMPLOYEE_TASK SUSPEND;
```

This stops future scheduled executions.

---

## Q4. How do you start the Task again?

```sql
ALTER TASK EMPLOYEE_TASK RESUME;
```

---

## Q5. How can you check Task execution history?

> We can use `INFORMATION_SCHEMA.TASK_HISTORY()` to check Task executions, status, scheduled time, start time, completion time, and errors.

---

## Q6. What is the difference between Task and Stream?

> A Stream tracks what data changed, while a Task determines when SQL or processing should run.

---

## Q7. Why did we use `EXECUTE IMMEDIATE`?

> We used it because the `COPY INTO` statement contains a dynamically generated filename, so the SQL statement needs to be constructed and executed dynamically.

---

# 🔥 Final Architecture

The complete pipeline can now be understood as:

```text
                    📋 EMPLOYEE
                         │
                         │
                      5 Records
                         │
                         ↓
                  ⚡ EMPLOYEE_TASK
                         │
                         │
                    ⏰ Every 1 Minute
                         │
                         ↓
                📝 Generate Filename
                         │
                         ↓
                    COPY INTO
                         │
                         ↓
              📦 CUSTOMER_EXPORT_STAGE
                         │
                         ↓
                    📄 CSV FILE
                         │
                         ↓
                  📊 TASK HISTORY
                         │
             ┌───────────┼───────────┐
             ↓           ↓           ↓
          ✅ SUCCESS   ❌ FAILED   🔄 RUNNING
                         │
                         ↓
                  🔍 Execution Details
                         │
              ┌──────────┼──────────┐
              ↓          ↓          ↓
            DATE       TIME      DURATION
             IST         IST
                         │
                         ↓
                  🔮 NEXT 5
                 EXPECTED RUNS
```

---

# 🧠 Final Mental Model

If you remember only one thing from this entire practice, remember this:

```text
             ⚡ TASK
                │
                │
        "When should SQL run?"
                │
                ↓
          ⏰ SCHEDULE
                │
                ↓
          ▶️ EXECUTE SQL
                │
                ↓
          📊 MONITOR RUN
                │
                ↓
        TASK_HISTORY
```

And the Task lifecycle:

```text
CREATE
  ↓
SUSPENDED
  ↓
RESUME
  ↓
SCHEDULED
  ↓
EXECUTE
  ↓
TASK_HISTORY
  ↓
SUSPEND
  ↓
RESUME AGAIN
```

### 🎯 One-line summary

> **Snowflake Task = automatically execute SQL at a defined time or based on a dependency, while Task History lets us monitor those executions.**
