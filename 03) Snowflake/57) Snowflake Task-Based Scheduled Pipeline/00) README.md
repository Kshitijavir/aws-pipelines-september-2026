# 57) Snowflake — Simple Task-Based Scheduled Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| 📘 [00) README.md](00%29%20README.md) | This guide |
| 🧾 [snowflake.sql](snowflake.sql) | Every SQL statement for this pipeline in one file, ready to paste into a Snowflake worksheet |

🚀 Now we move on to **Snowflake Tasks**.

For this practice, we will keep the pipeline very simple:

- 🗄️ One database
- 📂 One schema
- ⚙️ One warehouse
- 📋 One `EMPLOYEE` table
- 🔢 5 records
- ⚡ One Snowflake Task
- ⏱️ Task runs every 1 minute
- 📊 Task execution can be monitored through `TASK_HISTORY`
- 🔮 Next 5 expected executions can also be displayed

---

# 🧠 1. What Is a Snowflake Task?

A **Snowflake Task** is used to automatically execute SQL based on a schedule.

💡 Think:

```
📋 EMPLOYEE TABLE
      ↓
   ⚡ TASK
      ↓
⏱️ Every 1 minute
      ↓
  ▶️ Execute SQL
```

A Task can execute SQL directly or can call a stored procedure.

📌 For this practice, we are using a simple `SELECT` statement.

---

# 🎯 2. What We Will Build

🏗️ Our practice pipeline is:

```
📋 EMPLOYEE
   │
   │ 5 Records
   ↓
⚡ EMPLOYEE_TASK
   │
   │ ⏱️ Every 1 minute
   ↓
▶️ Execute SQL
   │
   ↓
📊 TASK HISTORY
```

🚫 We are **not** using:

- 🚫 Task chains
- 🚫 Child tasks
- 🚫 Root tasks
- 🚫 Streams
- 🚫 Summary tables
- 🚫 Target tables

📌 The purpose is simply to understand **Snowflake Task scheduling and monitoring**.

---

# 🗄️ Step 1 — Create the Database

```
CREATE DATABASE SNOWFLAKE_TASK_PRACTICE;

USE DATABASE SNOWFLAKE_TASK_PRACTICE;
```

---

# 📂 Step 2 — Create the Schema

```
CREATE SCHEMA TASK_SCHEMA;

USE SCHEMA TASK_SCHEMA;
```

---

# ⚙️ Step 3 — Create the Warehouse

```
CREATE WAREHOUSE TASK_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE TASK_WH;
```

### 💡 Why XSMALL?

This is only a small practice workload, so an XSMALL warehouse is enough.

```
AUTO_SUSPEND = 60
```

means the warehouse automatically suspends after 60 seconds of inactivity.

---

# 📋 Step 4 — Create the Employee Table

```
CREATE TABLE EMPLOYEE (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);
```

---

# ✍️ Step 5 — Insert 5 Records

```
INSERT INTO EMPLOYEE VALUES
(1001, 'Rahul', 'IT', 85000),
(1002, 'Priya', 'HR', 65000),
(1003, 'Amit', 'Finance', 95000),
(1004, 'Sneha', 'IT', 78000),
(1005, 'Vikas', 'Sales', 55000);
```

✅ Check the records:

```
SELECT * FROM EMPLOYEE;
```

You should see:

```
1001 Rahul
1002 Priya
1003 Amit
1004 Sneha
1005 Vikas
```

---

# ⚡ Step 6 — Create the Task

⚡ Now create the task.

```
CREATE TASK EMPLOYEE_TASK
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
SELECT * FROM EMPLOYEE;
```

### 🧩 What does this mean?

```
SCHEDULE = '1 MINUTE'
```

means:

> ⏱️ Snowflake schedules this task to execute every 1 minute.

The SQL executed by the task is:

```
SELECT * FROM EMPLOYEE;
```

---

# 🔍 Step 7 — Check the Task

```
SHOW TASKS LIKE 'EMPLOYEE_TASK';
```

🔍 When you first create the task, its state will be:

```
SUSPENDED
```

📌 This is expected.

Creating the task only **creates the task definition**. It does not start the scheduler.

---

# ▶️ Step 8 — Resume the Task

🚀 To allow Snowflake to start scheduling the task:

```
ALTER TASK EMPLOYEE_TASK RESUME;
```

Then check again:

```
SHOW TASKS LIKE 'EMPLOYEE_TASK';
```

✅ The task should now be in the started/running state.

---

# 🧠 Why and When Do We Use `ALTER TASK`?

📌 This is an important concept.

### 🧱 `CREATE TASK`

Used to **create the task**.

```
CREATE TASK EMPLOYEE_TASK
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
SELECT * FROM EMPLOYEE;
```

💡 Think:

```
🧱 CREATE TASK
     ↓
📝 Create the task definition
```

📌 The newly created task is initially suspended.

---

### ▶️ `ALTER TASK ... RESUME`

Used to **start/enable the task scheduler**.

```
ALTER TASK EMPLOYEE_TASK RESUME;
```

💡 Think:

```
🧱 Task created
     ↓
⏸️ SUSPENDED
     ↓
▶️ RESUME
     ↓
⏱️ Task starts getting scheduled
```

✅ Use `RESUME` when:

- 🆕 You create a new task and want it to start
- ▶️ You previously suspended the task
- 🔄 You want scheduled execution to continue again

---

### 🛑 `ALTER TASK ... SUSPEND`

Used to **stop future scheduled executions**.

```
ALTER TASK EMPLOYEE_TASK SUSPEND;
```

💡 Think:

```
▶️ Task running
     ↓
🛑 SUSPEND
     ↓
⏸️ Future scheduled executions stop
```

🛑 Use `SUSPEND` when:

- 🏁 You finish your practice
- 💰 You don't want the task to keep executing
- ⏸️ You temporarily want to stop scheduled processing
- 🔧 You need to make changes that require the task to be suspended

📌 The task is **not deleted**.

✅ You can start it again:

```
ALTER TASK EMPLOYEE_TASK RESUME;
```

### 🎤 Easy interview answer

> `CREATE TASK` creates the task definition. `ALTER TASK RESUME` starts task scheduling, and `ALTER TASK SUSPEND` stops future scheduled executions.

---

# 📊 Step 9 — Monitor Task Scheduling and Execution

👀 Use the following query to see:

- 🕘 Previous executions
- 📌 Current task state
- 📅 Scheduled time
- ▶️ Start time
- ✅ Completion time
- 🚦 Success/failed/running status
- ⏳ Execution duration
- 🔮 Next 5 expected executions
- 🇮🇳 IST date and time
- 🕛 12-hour AM/PM format

```
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
                DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
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

-- Previous / current executions
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
        CONVERT_TIMEZONE('Asia/Kolkata', SCHEDULED_TIME),
        'YYYY-MM-DD'
    ) AS EXECUTION_DATE_IST,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', SCHEDULED_TIME),
        'HH12:MI:SS AM'
    ) || ' IST' AS SCHEDULED_TIME_IST,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', QUERY_START_TIME),
        'HH12:MI:SS AM'
    ) || ' IST' AS START_TIME_IST,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', COMPLETED_TIME),
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

-- Next 5 expected executions
SELECT
    'EMPLOYEE_TASK' AS TASK_NAME,

    'UPCOMING' AS EXECUTION_STATUS,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', NEXT_SCHEDULE_TIME),
        'YYYY-MM-DD'
    ) AS EXECUTION_DATE_IST,

    TO_CHAR(
        CONVERT_TIMEZONE('Asia/Kolkata', NEXT_SCHEDULE_TIME),
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

# 📊 What This Monitoring Query Shows

📋 You will get columns such as:

| Column | Meaning |
| ------ | ------- |
| 🏷️ `TASK_NAME` | Name of the task |
| 🚦 `EXECUTION_STATUS` | SUCCESS / RUNNING / FAILED / SCHEDULED / UPCOMING |
| 📅 `EXECUTION_DATE_IST` | Execution date in IST |
| 🕘 `SCHEDULED_TIME_IST` | Scheduled time in IST |
| ▶️ `START_TIME_IST` | Actual execution start time |
| ✅ `COMPLETED_TIME_IST` | Execution completion time |
| ⏳ `EXECUTION_SECONDS` | How long execution took |
| 🚨 `ERROR_MESSAGE` | Error information if execution failed |

📝 Example:

```
EMPLOYEE_TASK | SUCCESS  | 2026-09-29 | 09:01:57 PM IST | 09:01:58 PM IST | 09:01:59 PM IST
EMPLOYEE_TASK | SUCCESS  | 2026-09-29 | 09:00:57 PM IST | 09:00:58 PM IST | 09:00:59 PM IST
EMPLOYEE_TASK | UPCOMING | 2026-09-29 | 09:02:57 PM IST | NULL           | NULL
```

🔮 The `UPCOMING` rows represent the **next 5 expected execution times** based on the task's 1-minute schedule.

---

# 🛑 Step 10 — Suspend the Task When Finished

🏁 When you are finished practicing:

```
ALTER TASK EMPLOYEE_TASK SUSPEND;
```

⏸️ This stops future scheduled executions.

🔍 You can verify:

```
SHOW TASKS LIKE 'EMPLOYEE_TASK';
```

You should see:

```
STATE = suspended
```

---

# 🔄 Step 11 — Resume Again When You Want to Practice

▶️ Whenever you want to start the task again:

```
ALTER TASK EMPLOYEE_TASK RESUME;
```

Then:

```
SHOW TASKS LIKE 'EMPLOYEE_TASK';
```

---

# ⏰ Schedule Options

⏰ We are using:

```
SCHEDULE = '1 MINUTE'
```

🕐 Other interval examples:

```
SCHEDULE = '5 MINUTE'
```

```
SCHEDULE = '1 HOUR'
```

📅 You can also use CRON scheduling.

Example:

```
SCHEDULE = 'USING CRON 0 19 * * * UTC'
```

🕖 This schedules the task for **7:00 PM UTC every day**.

---

# 🔥 Final Architecture

🏗️ Your entire practice pipeline is:

```
              📋 EMPLOYEE
                  │
                  │ 5 records
                  ↓
            ⚡ EMPLOYEE_TASK
                  │
                  │
             ⏱️ Every 1 minute
                  │
                  ↓
             ▶️ Execute SQL
                  │
                  ↓
           📊 TASK HISTORY
                  │
       ┌──────────┼──────────┐
       ↓          ↓          ↓
   ✅ SUCCESS  ❌ FAILED  🔄 RUNNING
                  │
                  ↓
          🔍 Execution Details
                  │
        ┌─────────┼─────────┐
        ↓         ↓         ↓
      📅 DATE   🕘 TIME   ⏳ DURATION
        IST       IST
                  │
                  ↓
          🔮 NEXT 5 EXECUTIONS
              UPCOMING
```

---

# 🧠 Task vs Stream

📌 Keep this difference clear.

### 🌊 Stream

```
🌊 STREAM = WHAT CHANGED?
```

A Stream tracks changes made to table data.

### ⏰ Task

```
⏰ TASK = WHEN SHOULD SQL RUN?
```

A Task automatically executes SQL based on a schedule or dependency.

🔗 Together they can be used as:

```
📋 SOURCE TABLE
     ↓
🌊 STREAM
"What changed?"
     ↓
⏰ TASK
"When/process it?"
     ↓
🎯 TARGET
```

📌 For this practice, we are intentionally keeping it simple and learning **Tasks first** without adding Streams or Task chains.
