# 57) Snowflake — Task-Based Scheduled Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This guide |
| [snowflake.sql](snowflake.sql) | Every SQL statement for this pipeline in one file, ready to paste into a Snowflake worksheet |

Now we move on to **Snowflake Tasks**. You already know the basic idea: a task is used for scheduling. A task is a job that Snowflake runs for you on a schedule. Now we will build a pipeline where Snowflake runs SQL by itself on a schedule.

---

## 🧠 First: What Is a Snowflake Task?

A **task is Snowflake's way to schedule and run SQL**.

It can run SQL by itself. It can also call a stored procedure. It runs on a schedule, or after another task.

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

For this practice, let's start simple:

```text
SOURCE TABLE
     ↓
   TASK
     ↓
SQL Transformation
     ↓
TARGET TABLE
```

Then we'll build a **chain of tasks**:

```text
TASK 1
  ↓
TASK 2
  ↓
TASK 3
```

This matters because Snowflake tasks are not only about time. They can also run one after another.

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

* Creating a task
* `SCHEDULE`
* `USING CRON`
* `AFTER`
* Task dependencies (one task runs after another)
* `ALTER TASK ... RESUME`
* `ALTER TASK ... SUSPEND`
* `TASK_HISTORY`
* Task execution (watching a task run)
* Chains of tasks

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

This table will hold the changed data.

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

We'll make a simple task. It runs every minute.

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

> Run this task every minute.

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

Creating a task does **not start it right away**.

You must start it again.

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

Wait about 1 to 2 minutes.

Then:

```sql
SELECT * FROM EMPLOYEE_TARGET;
```

You should see the new rows.

---

## 🕘 Step 11 — Check Task History

This part is very important.

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

You can see things like:

```text
STATE
SCHEDULED_TIME
QUERY_START_TIME
COMPLETED_TIME
ERROR_MESSAGE
```

This shows you if the task ran fine or not.

---

## 🛑 Step 12 — Suspend the Task

For practice, don't leave it running all the time.

```sql
ALTER TASK EMPLOYEE_LOAD_TASK SUSPEND;
```

Now it stops starting new runs.

---

## 🔗 Step 13 — Create a Task Chain

Now let's learn something bigger.

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

This is called a **chain of tasks**. One task runs first. The next one runs after it.

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

First, create the parent task.

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

> Don't run this task on its own. Run it after the parent task works.

---

## ▶️ Step 17 — Resume the Child First

This is a key idea in Snowflake tasks.

Stop both first if you need to:

```sql
ALTER TASK DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK EMPLOYEE_ROOT_TASK SUSPEND;
```

Then start the child again:

```sql
ALTER TASK DEPARTMENT_SUMMARY_TASK RESUME;
```

Then start the parent again:

```sql
ALTER TASK EMPLOYEE_ROOT_TASK RESUME;
```

Now:

```text
EMPLOYEE_ROOT_TASK
         ↓
DEPARTMENT_SUMMARY_TASK
```

The parent task controls the schedule.

---

## 🧠 Why Resume the Child First?

In a chain of tasks, Snowflake wants the child task started first. Then you start the parent task.

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

You should see something like this:

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

When you finish practice:

```sql
ALTER TASK DEPARTMENT_SUMMARY_TASK SUSPEND;
ALTER TASK EMPLOYEE_ROOT_TASK SUSPEND;
```

This stops it from running again and again.

---

## 🧠 Schedule Types

We have used:

```sql
SCHEDULE = '1 MINUTE'
```

You can also use CRON.

For example:

```sql
SCHEDULE = 'USING CRON 0 19 * * * UTC'
```

In plain words:

```text
Every day
    ↓
7:00 PM UTC
    ↓
Task executes
```

You can also use time gaps like:

```sql
SCHEDULE = '5 MINUTE'
```

or:

```sql
SCHEDULE = '1 HOUR'
```

---

## 🔥 The Big Picture

You should now know:

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

This difference is **very important**. We just finished Streams.

### 🌊 Stream

```text
Stream = WHAT changed?
```

It remembers what changed in a table.

### ⏰ Task

```text
Task = WHEN / HOW should something execute?
```

It runs SQL by itself.

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

This **Stream + Task** pair is one of the most useful Snowflake patterns to know.

