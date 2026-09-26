# 57) Snowflake — Task-Based Scheduled Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |

Now we move to **Snowflake Tasks**. You already know the basic idea that a Task is used for scheduling. Now we'll actually build a pipeline where Snowflake automatically executes SQL on a schedule.

---

## 🧠 First: What Is a Snowflake Task?

A **Task is Snowflake's scheduler/execution mechanism**.

It can automatically execute SQL or call a stored procedure according to a schedule or dependency.

Think:

```text
             TASK
              │
              │ Every 1 minute
              ↓
        Execute SQL
              │
              ↓
       Transform Data
              │
              ↓
          Target Table
```

For this practical, we'll start simple:

```text
SOURCE TABLE
     ↓
   TASK
     ↓
SQL Transformation
     ↓
TARGET TABLE
```

Then we'll build a **Task Chain**:

```text
TASK 1
  ↓
TASK 2
  ↓
TASK 3
```

This is important because Snowflake Tasks aren't only about time-based scheduling.

---

## 🎯 What We'll Build

We'll build:

```text
EMPLOYEE_SOURCE
      ↓
   TASK 1
      ↓
TRANSFORMED_EMPLOYEE
      ↓
   TASK 2
      ↓
EMPLOYEE_SUMMARY
```

And we'll practice:

* Creating a Task
* `SCHEDULE`
* `USING CRON`
* `AFTER`
* Task dependencies
* `ALTER TASK ... RESUME`
* `ALTER TASK ... SUSPEND`
* `TASK_HISTORY`
* Task execution
* Task chains

---

## 🗄️ Step 1 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_TASK_PRACTICE;

USE DATABASE SNOWFLAKE_TASK_PRACTICE;
```

---

## 📂 Step 2 — Create the Schema

```sql
CREATE SCHEMA TASK_SCHEMA;

USE SCHEMA TASK_SCHEMA;
```

---

## ⚙️ Step 3 — Create the Warehouse

```sql
CREATE WAREHOUSE TASK_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE TASK_WH;
```

---

## 📋 Step 4 — Create the Source Table

```sql
CREATE TABLE EMPLOYEE_SOURCE (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);
```

---

## ✍️ Step 5 — Insert Initial Data

```sql
INSERT INTO EMPLOYEE_SOURCE VALUES
(8001, 'Rahul Sharma', 'IT', 85000),
(8002, 'Priya Patil', 'HR', 62000),
(8003, 'Amit Verma', 'Finance', 95000),
(8004, 'Sneha Joshi', 'IT', 78000),
(8005, 'Vikas Kumar', 'Sales', 58000);
```

Check:

```sql
SELECT * FROM EMPLOYEE_SOURCE;
```

---

## 📋 Step 6 — Create the Target Table

This table will contain the transformed data.

```sql
CREATE TABLE EMPLOYEE_TARGET (
    EMPLOYEE_ID     NUMBER,
    EMPLOYEE_NAME   VARCHAR(100),
    DEPARTMENT      VARCHAR(50),
    SALARY          NUMBER,
    SALARY_CATEGORY VARCHAR(20),
    LOAD_TIME       TIMESTAMP
);
```

---

## ⚡ Step 7 — Create Our First Task

We'll make a simple Task that executes every minute.

```sql
CREATE TASK EMPLOYEE_LOAD_TASK
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
INSERT INTO EMPLOYEE_TARGET
SELECT
    EMPLOYEE_ID,
    UPPER(EMPLOYEE_NAME),
    DEPARTMENT,
    SALARY,
    CASE
        WHEN SALARY >= 100000 THEN 'HIGH'
        WHEN SALARY >= 70000  THEN 'MEDIUM'
        ELSE 'LOW'
    END,
    CURRENT_TIMESTAMP()
FROM EMPLOYEE_SOURCE;
```

### 💡 Notice

```text
SCHEDULE = '1 MINUTE'
```

means:

> Execute this Task every minute.

---

## 🔍 Step 8 — Check the Task

```sql
SHOW TASKS;
```

You should see:

```text
EMPLOYEE_LOAD_TASK
```

---

## ⚠️ Step 9 — Task Is Initially Suspended

Creating a Task does **not mean it immediately starts running**.

You need to resume it.

```sql
ALTER TASK EMPLOYEE_LOAD_TASK RESUME;
```

Now:

```text
Task
 ↓
RESUMED
 ↓
Scheduler can execute it
```

---

## ⏳ Step 10 — Wait and Check the Target

Wait around 1–2 minutes.

Then:

```sql
SELECT * FROM EMPLOYEE_TARGET;
```

You should see the transformed rows.

---

## 🕘 Step 11 — Check Task History

This is very important.

```sql
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'EMPLOYEE_LOAD_TASK',
        SCHEDULED_TIME_RANGE_START => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY SCHEDULED_TIME DESC;
```

You'll be able to see things such as:

```text
STATE
SCHEDULED_TIME
QUERY_START_TIME
COMPLETED_TIME
ERROR_MESSAGE
```

This lets you check whether the Task executed successfully.

---

## 🛑 Step 12 — Suspend the Task

For practice, don't leave it running continuously.

```sql
ALTER TASK EMPLOYEE_LOAD_TASK SUSPEND;
```

Now it stops scheduling executions.

---

## 🔗 Step 13 — Create a Task Chain

Now let's learn something more important.

Suppose we want:

```text
Task 1
  ↓
Task 2
  ↓
Task 3
```

Example:

```text
TASK 1
Load employee data
         ↓
TASK 2
Calculate department summary
         ↓
TASK 3
Final processing
```

This is called a **Task Graph / Task Dependency**.

---

## 📋 Step 14 — Create the Summary Table

```sql
CREATE TABLE DEPARTMENT_SUMMARY (
    DEPARTMENT      VARCHAR(50),
    EMPLOYEE_COUNT  NUMBER,
    TOTAL_SALARY    NUMBER,
    AVG_SALARY      NUMBER,
    LOAD_TIME       TIMESTAMP
);
```

---

## 🌱 Step 15 — Create the Root Task

First create the parent Task.

```sql
CREATE TASK EMPLOYEE_ROOT_TASK
    WAREHOUSE = TASK_WH
    SCHEDULE = '5 MINUTE'
AS
INSERT INTO EMPLOYEE_TARGET
SELECT
    EMPLOYEE_ID,
    UPPER(EMPLOYEE_NAME),
    DEPARTMENT,
    SALARY,
    CASE
        WHEN SALARY >= 100000 THEN 'HIGH'
        WHEN SALARY >= 70000  THEN 'MEDIUM'
        ELSE 'LOW'
    END,
    CURRENT_TIMESTAMP()
FROM EMPLOYEE_SOURCE;
```

---

## 🌿 Step 16 — Create the Child Task

Now:

```sql
CREATE TASK DEPARTMENT_SUMMARY_TASK
    WAREHOUSE = TASK_WH
    AFTER EMPLOYEE_ROOT_TASK
AS
INSERT INTO DEPARTMENT_SUMMARY
SELECT
    DEPARTMENT,
    COUNT(*),
    SUM(SALARY),
    AVG(SALARY),
    CURRENT_TIMESTAMP()
FROM EMPLOYEE_TARGET
GROUP BY DEPARTMENT;
```

Notice:

```sql
AFTER EMPLOYEE_ROOT_TASK
```

This means:

> Don't run this Task independently. Run it after the parent Task succeeds.

---

## ▶️ Step 17 — Resume the Child First

This is a very important Snowflake Task concept.

Suspend both first if necessary:

```sql
ALTER TASK DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK EMPLOYEE_ROOT_TASK SUSPEND;
```

Then resume the child:

```sql
ALTER TASK DEPARTMENT_SUMMARY_TASK RESUME;
```

Then resume the root:

```sql
ALTER TASK EMPLOYEE_ROOT_TASK RESUME;
```

Now:

```text
EMPLOYEE_ROOT_TASK
         ↓
DEPARTMENT_SUMMARY_TASK
```

The root Task controls the schedule.

---

## 🧠 Why Resume the Child First?

Snowflake requires child Tasks to be resumed before the root Task is resumed for a task graph.

Think:

```text
Child ready
   ↓
Root starts
   ↓
Root completes
   ↓
Child executes
```

---

## 🗺️ Step 18 — Check the Task Graph

```sql
SHOW TASKS;
```

You should see something like:

```text
EMPLOYEE_ROOT_TASK
         ↓
DEPARTMENT_SUMMARY_TASK
```

---

## 🕘 Step 19 — Check Task History

```sql
SELECT
    NAME,
    STATE,
    SCHEDULED_TIME,
    QUERY_START_TIME,
    COMPLETED_TIME,
    ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        SCHEDULED_TIME_RANGE_START = DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY SCHEDULED_TIME DESC;
```

---

## 🛑 Step 20 — Suspend Everything

When finished practicing:

```sql
ALTER TASK DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK EMPLOYEE_ROOT_TASK SUSPEND;
```

This prevents unnecessary repeated execution.

---

## 🧠 Schedule Types

We've used:

```sql
SCHEDULE = '1 MINUTE'
```

You can also use CRON.

For example:

```sql
SCHEDULE = 'USING CRON 0 19 * * * UTC'
```

Conceptually:

```text
Every day
    ↓
7:00 PM UTC
    ↓
Task executes
```

You can also use intervals such as:

```sql
SCHEDULE = '5 MINUTE'
```

or:

```sql
SCHEDULE = '1 HOUR'
```

---

## 🔥 The Big Picture

You should now understand:

### 🕐 Simple Task

```text
Schedule
   ↓
Task
   ↓
SQL
   ↓
Table
```

### 🔗 Task Chain

```text
                 ROOT TASK
                     │
                     ↓
              TRANSFORMATION
                     │
                     ↓
                  TASK 2
                     │
                     ↓
                 SUMMARY
```

---

## 🧠 Task vs Stream

This distinction is **very important** because we just completed Streams.

### 🌊 Stream

```text
Stream = WHAT changed?
```

It captures table changes.

### ⏰ Task

```text
Task = WHEN / HOW should something execute?
```

It executes SQL automatically.

Together:

```text
             SOURCE TABLE
                  │
                  ↓
               STREAM
           "What changed?"
                  │
                  ↓
                TASK
        "Process the changes"
                  │
                  ↓
              TARGET
```

This **Stream + Task** combination is one of the most useful Snowflake patterns to understand.

