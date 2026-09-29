# 57) Snowflake — Multi Stage Export Using Multi Task

## 📁 Files in This Folder

| File               | What It Is                           |
| ------------------ | ------------------------------------ |
| 📘 `README.md`     | This guide                           |
| 🧾 `snowflake.sql` | Complete SQL script for the pipeline |

---

# 🚀 What Are We Building?

This practice is the **multi version** of the single stage export practice.

In the earlier practice we had **one** table, **one** stage and **one** Task.

Now we build **four** of everything:

| Piece              | How Many | Names                                                                 |
| ------------------ | -------- | --------------------------------------------------------------------- |
| 📋 Source tables    | 4        | `EMPLOYEE_DATA_1` … `EMPLOYEE_DATA_4`                                 |
| 📄 CSV file formats | 4        | `CUSTOMER_EXPORT_CSV_FORMAT_1` … `CUSTOMER_EXPORT_CSV_FORMAT_4`        |
| 📦 Internal stages  | 4        | `CUSTOMER_EXPORT_STAGE_1` … `CUSTOMER_EXPORT_STAGE_4`                  |
| ⚡ Tasks            | 4        | `EMPLOYEE_TASK_1` … `EMPLOYEE_TASK_4`                                  |

Each Task owns exactly one table and one stage:

```text
📋 EMPLOYEE_DATA_1  →  ⚡ EMPLOYEE_TASK_1  →  📦 CUSTOMER_EXPORT_STAGE_1
📋 EMPLOYEE_DATA_2  →  ⚡ EMPLOYEE_TASK_2  →  📦 CUSTOMER_EXPORT_STAGE_2
📋 EMPLOYEE_DATA_3  →  ⚡ EMPLOYEE_TASK_3  →  📦 CUSTOMER_EXPORT_STAGE_3
📋 EMPLOYEE_DATA_4  →  ⚡ EMPLOYEE_TASK_4  →  📦 CUSTOMER_EXPORT_STAGE_4
```

So this practice gives you **four independent exports running side by side, every 1 minute**.

The important part is not the employee data itself.

The goal is to understand:

* ⚡ What a Snowflake Task is
* ⏰ How task scheduling works
* ▶️ How to start a Task
* 🛑 How to stop a Task
* 📁 How a Task can execute `COPY INTO`
* 📝 How to generate a dynamic filename
* 📦 How to export data to an internal stage
* 🔀 How several Tasks run at the same time, one per stage
* 📊 How to monitor Task execution
* 🔍 How to check success/failure
* 🔮 How to calculate upcoming executions
* 💡 Difference between `CREATE`, `RESUME`, and `SUSPEND`

---

# 🧠 1. First Understand the Problem

Imagine we have four tables:

```text
EMPLOYEE_DATA_1   │
EMPLOYEE_DATA_2   │  Employee data
EMPLOYEE_DATA_3   │
EMPLOYEE_DATA_4   │
                  ↓
Need to export every table automatically
                  │
                  ↓
           Every 1 minute
                  │
                  ↓
   One CSV file per table
                  │
                  ↓
   Store the CSV files in Snowflake Stages
```

Without Tasks, we would have to manually execute four statements:

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE_1/employee_data_1.csv
FROM EMPLOYEE_DATA_1;

COPY INTO @CUSTOMER_EXPORT_STAGE_2/employee_data_2.csv
FROM EMPLOYEE_DATA_2;

COPY INTO @CUSTOMER_EXPORT_STAGE_3/employee_data_3.csv
FROM EMPLOYEE_DATA_3;

COPY INTO @CUSTOMER_EXPORT_STAGE_4/employee_data_4.csv
FROM EMPLOYEE_DATA_4;
```

every time we wanted fresh exports.

That is not automation.

Instead, we want Snowflake to automatically execute all four exports for us.

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

In our pipeline, four Tasks run together:

```text
📋 EMPLOYEE_DATA_1  →  ⚡ EMPLOYEE_TASK_1  ┐
📋 EMPLOYEE_DATA_2  →  ⚡ EMPLOYEE_TASK_2  │
📋 EMPLOYEE_DATA_3  →  ⚡ EMPLOYEE_TASK_3  │  Every 1 minute
📋 EMPLOYEE_DATA_4  →  ⚡ EMPLOYEE_TASK_4  ┘
                        │
                        ↓
            Generate CSV filename
                        │
                        ↓
                   COPY INTO
                        │
                        ↓
            Four INTERNAL STAGES
```

### 🎤 Simple interview answer

> A Snowflake Task is used to automatically execute SQL or a stored procedure based on a schedule or dependency.

---

# 🎯 3. What Exactly Will These Tasks Do?

Our four Tasks will perform the following steps:

```text
1. All four Tasks wake up every 1 minute
          ↓
2. Each Task generates its own unique CSV filename
          ↓
3. Each Task executes COPY INTO
          ↓
4. Each Task reads its own source table
          ↓
5. Each Task writes to its own internal stage
          ↓
6. Every execution is recorded in Task History
```

For example, one run may generate:

```text
employee_data_1_export_20260930_012300.csv
employee_data_2_export_20260930_012300.csv
employee_data_3_export_20260930_012300.csv
employee_data_4_export_20260930_012300.csv
```

and place each file in its own stage:

```text
@CUSTOMER_EXPORT_STAGE_1
@CUSTOMER_EXPORT_STAGE_2
@CUSTOMER_EXPORT_STAGE_3
@CUSTOMER_EXPORT_STAGE_4
```

---

# 🏗️ 4. Complete Architecture

The complete practice pipeline is:

```text
      📋 EMPLOYEE_DATA_1   📋 EMPLOYEE_DATA_2   📋 EMPLOYEE_DATA_3   📋 EMPLOYEE_DATA_4
             │                    │                    │                    │
             │ 5 records          │ 5 records          │ 5 records          │ 5 records
             ↓                    ↓                    ↓                    ↓
      ⚡ EMPLOYEE_TASK_1    ⚡ EMPLOYEE_TASK_2    ⚡ EMPLOYEE_TASK_3    ⚡ EMPLOYEE_TASK_4
             │                    │                    │                    │
             └────────────────────┴─────────┬──────────┴────────────────────┘
                                            │
                                    ⏰ Every 1 minute
                                            │
                                            ↓
                                  📝 Generate Filename
                                            │
                                            ↓
                                       COPY INTO
                                            │
                    ┌───────────────┬───────┴───────┬───────────────┐
                    ↓               ↓               ↓               ↓
          📦 STAGE_1        📦 STAGE_2       📦 STAGE_3      📦 STAGE_4
                    │               │               │               │
                    ↓               ↓               ↓               ↓
                 📄 CSV          📄 CSV          📄 CSV          📄 CSV
                    └───────────────┴───────┬───────┴───────────────┘
                                            │
                                            ↓
                                     📊 TASK HISTORY
                                            │
                              ┌─────────────┼─────────────┐
                              ↓             ↓             ↓
                          ✅ SUCCESS    ❌ FAILED    🔄 RUNNING
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

Each Task is **independent**. No Task waits for another Task.

That keeps the difference from the single stage practice very small — we simply have four of everything.

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

The Tasks need compute to execute the SQL.

Create a small warehouse:

```sql
CREATE WAREHOUSE TASK_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE TASK_WH;
```

### 💡 Why XSMALL?

This is still a very small practice workload.

We only have:

```text
4 tables
20 records in total
4 COPY INTO operations
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

# 📋 Step 4 — Create the Four Employee Tables

Now create our four source tables.

```sql
CREATE TABLE EMPLOYEE_DATA_1 (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

SELECT * FROM EMPLOYEE_DATA_1;
```

```sql
CREATE TABLE EMPLOYEE_DATA_2 (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

SELECT * FROM EMPLOYEE_DATA_2;
```

```sql
CREATE TABLE EMPLOYEE_DATA_3 (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

SELECT * FROM EMPLOYEE_DATA_3;
```

```sql
CREATE TABLE EMPLOYEE_DATA_4 (
    EMPLOYEE_ID NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY NUMBER
);

SELECT * FROM EMPLOYEE_DATA_4;
```

All four tables have the same columns:

| Column          | Description         |
| --------------- | ------------------- |
| `EMPLOYEE_ID`   | Employee ID         |
| `EMPLOYEE_NAME` | Employee name       |
| `DEPARTMENT`    | Employee department |
| `SALARY`        | Employee salary     |

At this point, all four tables are empty.

---

# ✍️ Step 5 — Insert Data Into the Four Tables

Each table gets its **own** five records.

```sql
INSERT INTO EMPLOYEE_DATA_1 VALUES
(1001, 'Rahul', 'IT', 85000),
(1002, 'Priya', 'HR', 65000),
(1003, 'Amit', 'Finance', 95000),
(1004, 'Sneha', 'IT', 78000),
(1005, 'Vikas', 'Sales', 55000);

SELECT * FROM EMPLOYEE_DATA_1;
```

```sql
INSERT INTO EMPLOYEE_DATA_2 VALUES
(2001, 'Rohit', 'IT', 72000),
(2002, 'Kavita', 'HR', 61000),
(2003, 'Manoj', 'Finance', 88000),
(2004, 'Pooja', 'IT', 69000),
(2005, 'Suresh', 'Sales', 52000);

SELECT * FROM EMPLOYEE_DATA_2;
```

```sql
INSERT INTO EMPLOYEE_DATA_3 VALUES
(3001, 'Arjun', 'IT', 91000),
(3002, 'Neha', 'HR', 67000),
(3003, 'Ravi', 'Finance', 83000),
(3004, 'Meera', 'IT', 76000),
(3005, 'Karan', 'Sales', 59000);

SELECT * FROM EMPLOYEE_DATA_3;
```

```sql
INSERT INTO EMPLOYEE_DATA_4 VALUES
(4001, 'Deepak', 'IT', 81000),
(4002, 'Anita', 'HR', 64000),
(4003, 'Sunil', 'Finance', 99000),
(4004, 'Ritu', 'IT', 70000),
(4005, 'Anil', 'Sales', 54000);

SELECT * FROM EMPLOYEE_DATA_4;
```

You should now have:

```text
EMPLOYEE_DATA_1  →  1001 - 1005  (5 records)
EMPLOYEE_DATA_2  →  2001 - 2005  (5 records)
EMPLOYEE_DATA_3  →  3001 - 3005  (5 records)
EMPLOYEE_DATA_4  →  4001 - 4005  (5 records)
```

---

# 📄 Step 6 — Create the Four CSV File Formats

Because we are exporting the employee data as CSV, create one CSV file format per stage.

```sql
CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_1
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_2
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_3
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT_4
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';
```

### What does this define?

It tells Snowflake how the exported files should be formatted.

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

# 📦 Step 7 — Create the Four Internal Stages

Now create one internal stage per table.

```sql
CREATE STAGE CUSTOMER_EXPORT_STAGE_1
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_1;

CREATE STAGE CUSTOMER_EXPORT_STAGE_2
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_2;

CREATE STAGE CUSTOMER_EXPORT_STAGE_3
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_3;

CREATE STAGE CUSTOMER_EXPORT_STAGE_4
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT_4;
```

Think of a Stage as a **file storage location inside Snowflake**.

Our flow is:

```text
EMPLOYEE_DATA_1 → CUSTOMER_EXPORT_STAGE_1 → CSV FILE
EMPLOYEE_DATA_2 → CUSTOMER_EXPORT_STAGE_2 → CSV FILE
EMPLOYEE_DATA_3 → CUSTOMER_EXPORT_STAGE_3 → CSV FILE
EMPLOYEE_DATA_4 → CUSTOMER_EXPORT_STAGE_4 → CSV FILE
```

---

# ⚡ Step 8 — Create the Four Snowflake Tasks

Now we reach the most important part.

Create four Tasks, one per table and stage:

```sql
CREATE TASK EMPLOYEE_TASK_1
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_data_1_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE_1/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE_DATA_1';

END;
```

```sql
CREATE TASK EMPLOYEE_TASK_2
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_data_2_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE_2/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE_DATA_2';

END;
```

```sql
CREATE TASK EMPLOYEE_TASK_3
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_data_3_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE_3/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE_DATA_3';

END;
```

```sql
CREATE TASK EMPLOYEE_TASK_4
    WAREHOUSE = TASK_WH
    SCHEDULE = '1 MINUTE'
AS
DECLARE
    FILE_NAME VARCHAR;
BEGIN

    FILE_NAME :=
        'employee_data_4_export_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISS'
        ) ||
        '.csv';

    EXECUTE IMMEDIATE
        'COPY INTO @CUSTOMER_EXPORT_STAGE_4/' ||
        FILE_NAME ||
        ' FROM EMPLOYEE_DATA_4';

END;
```

---

# 🧩 Step 8.1 — Understand the Task Definition

Let's break one Task down.

### Task name

```sql
CREATE TASK EMPLOYEE_TASK_1
```

Creates a Task called:

```text
EMPLOYEE_TASK_1
```

The other three Tasks follow the same pattern:

```text
EMPLOYEE_TASK_2
EMPLOYEE_TASK_3
EMPLOYEE_TASK_4
```

---

### Warehouse

```sql
WAREHOUSE = TASK_WH
```

Tells the Task which warehouse to use when executing the SQL.

All four Tasks use the same warehouse.

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
12:01 → All four Tasks execute
12:02 → All four Tasks execute
12:03 → All four Tasks execute
12:04 → All four Tasks execute
...
```

---

# 📝 Step 8.2 — Generate the Filename

Inside each Task we create:

```sql
FILE_NAME :=
    'employee_data_1_export_' ||
    TO_VARCHAR(
        CURRENT_TIMESTAMP(),
        'YYYYMMDD_HH24MISS'
    ) ||
    '.csv';
```

This dynamically creates a filename.

For example:

```text
employee_data_1_export_20260930_012300.csv
```

Only the number changes from Task to Task:

```text
employee_data_1_export_20260930_012300.csv
employee_data_2_export_20260930_012300.csv
employee_data_3_export_20260930_012300.csv
employee_data_4_export_20260930_012300.csv
```

So every execution can generate a different filename, and no file overwrites another.

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
employee_data_1_export_20260930_012300.csv
```

is generated.

---

# 🧩 Step 8.4 — What Does `EXECUTE IMMEDIATE` Do?

The final command inside each Task is:

```sql
EXECUTE IMMEDIATE
    'COPY INTO @CUSTOMER_EXPORT_STAGE_1/' ||
    FILE_NAME ||
    ' FROM EMPLOYEE_DATA_1';
```

Because `FILE_NAME` is dynamically generated, we construct the SQL statement dynamically.

For example, Snowflake effectively builds:

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE_1/employee_data_1_export_20260930_012300.csv
FROM EMPLOYEE_DATA_1;
```

So each Task is doing:

```text
Generate filename
       ↓
Build COPY INTO statement
       ↓
Execute COPY INTO
       ↓
Export its own table
       ↓
Create CSV in its own Stage
```

---

# 🔀 Step 8.5 — The Table → Stage → Task Mapping

This table is the heart of the multi pipeline:

| Task               | Reads              | Writes to                        | Filename prefix                     |
| ------------------ | ------------------ | -------------------------------- | ----------------------------------- |
| `EMPLOYEE_TASK_1`  | `EMPLOYEE_DATA_1`  | `@CUSTOMER_EXPORT_STAGE_1`        | `employee_data_1_export_<time>.csv` |
| `EMPLOYEE_TASK_2`  | `EMPLOYEE_DATA_2`  | `@CUSTOMER_EXPORT_STAGE_2`        | `employee_data_2_export_<time>.csv` |
| `EMPLOYEE_TASK_3`  | `EMPLOYEE_DATA_3`  | `@CUSTOMER_EXPORT_STAGE_3`        | `employee_data_3_export_<time>.csv` |
| `EMPLOYEE_TASK_4`  | `EMPLOYEE_DATA_4`  | `@CUSTOMER_EXPORT_STAGE_4`        | `employee_data_4_export_<time>.csv` |

One Task never touches another Task's table or stage.

That is what makes the four exports **independent**.

---

# ⏸️ Step 9 — Important: A New Task Starts Suspended

After creating the Tasks:

```sql
CREATE TASK EMPLOYEE_TASK_1
...
```

the Tasks do **not** immediately start executing.

A newly created Task is initially:

```text
SUSPENDED
```

Check them:

```sql
SHOW TASKS LIKE 'EMPLOYEE_TASK_%';
```

You should see all four Tasks in suspended state.

---

# 🧠 10. `CREATE TASK` vs `RESUME` vs `SUSPEND`

This is one of the most important concepts to remember.

## 🧱 `CREATE TASK`

```sql
CREATE TASK EMPLOYEE_TASK_1
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
ALTER TASK EMPLOYEE_TASK_1 RESUME;
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
ALTER TASK EMPLOYEE_TASK_1 SUSPEND;
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
ALTER TASK EMPLOYEE_TASK_1 RESUME;
```

---

# 🎤 Easy Interview Answer

> `CREATE TASK` creates the Task definition. `RESUME` enables Task scheduling, and `SUSPEND` stops future scheduled executions.

---

# ▶️ Step 10 — Resume the Tasks

Now start the scheduler for all four Tasks:

```sql
ALTER TASK EMPLOYEE_TASK_1 RESUME;
ALTER TASK EMPLOYEE_TASK_2 RESUME;
ALTER TASK EMPLOYEE_TASK_3 RESUME;
ALTER TASK EMPLOYEE_TASK_4 RESUME;
```

Check again:

```sql
SHOW TASKS LIKE 'EMPLOYEE_TASK_%';
```

All four Tasks are now enabled for scheduling.

The flow becomes:

```text
CREATE TASK 1..4
     ↓
SUSPENDED
     ↓
RESUME 1..4
     ↓
SCHEDULE ACTIVE
     ↓
Every 1 minute
     ↓
Execute all four Tasks
```

---

# 📊 Step 11 — Understand What Happens During Execution

Once the Tasks start executing:

```text
EMPLOYEE_TASK_1  →  COPY INTO  →  CUSTOMER_EXPORT_STAGE_1
EMPLOYEE_TASK_2  →  COPY INTO  →  CUSTOMER_EXPORT_STAGE_2
EMPLOYEE_TASK_3  →  COPY INTO  →  CUSTOMER_EXPORT_STAGE_3
EMPLOYEE_TASK_4  →  COPY INTO  →  CUSTOMER_EXPORT_STAGE_4
```

Every Task follows the same path:

```text
Wait for scheduled time
      │
      ↓
Generate filename
      │
      ↓
COPY INTO
      │
      ↓
Read its own table
      │
      ↓
Write CSV
      │
      ↓
Its own stage
```

For example:

```text
employee_data_1_export_20260930_012300.csv
```

will be created in stage 1, and the matching files in the other stages.

You can check a stage with:

```sql
LIST @CUSTOMER_EXPORT_STAGE_1;
```

---

# 📊 Step 12 — Monitor Task Execution

Now we need to answer an important question:

> How do I know whether my Tasks actually ran successfully?

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
* Next 5 expected executions for each Task
* IST date/time

Because we now have four Tasks, the query shows the history of **all four Tasks together**.

---

# 🔍 Step 13 — Task History Query

```sql
WITH TASK_NAMES AS (

    SELECT 'EMPLOYEE_TASK_1' AS TASK_NAME
    UNION ALL
    SELECT 'EMPLOYEE_TASK_2'
    UNION ALL
    SELECT 'EMPLOYEE_TASK_3'
    UNION ALL
    SELECT 'EMPLOYEE_TASK_4'
),

TASK_HISTORY_DATA AS (

    SELECT
        NAME,
        STATE,
        SCHEDULED_TIME,
        QUERY_START_TIME,
        COMPLETED_TIME,
        ERROR_MESSAGE

    FROM TABLE(
        INFORMATION_SCHEMA.TASK_HISTORY(
            SCHEDULED_TIME_RANGE_START =>
                DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
        )
    )

    -- Keep only the four tasks of this practice
    WHERE NAME IN (
        'EMPLOYEE_TASK_1',
        'EMPLOYEE_TASK_2',
        'EMPLOYEE_TASK_3',
        'EMPLOYEE_TASK_4'
    )
),

LATEST_SCHEDULE AS (

    SELECT
        MAX(SCHEDULED_TIME) AS LAST_SCHEDULED_TIME

    FROM TASK_HISTORY_DATA
),

NEXT_5_EXECUTIONS AS (

    SELECT
        TASK_NAME,

        DATEADD(
            MINUTE,
            ROW_NUMBER() OVER (
                PARTITION BY TASK_NAME
                ORDER BY SEQ4()
            ),
            LAST_SCHEDULED_TIME
        ) AS NEXT_SCHEDULE_TIME

    FROM TASK_NAMES,
         LATEST_SCHEDULE,
         TABLE(GENERATOR(ROWCOUNT => 5))
)

-- ============================================================
-- Previous / Current Task Executions
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
-- Next 5 Expected Executions For Each Task
-- ============================================================

SELECT

    TASK_NAME,

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

This time we do **not** pass a single Task name. We ask for the history of the whole time range and then keep only our four Tasks:

```sql
WHERE NAME IN (
    'EMPLOYEE_TASK_1',
    'EMPLOYEE_TASK_2',
    'EMPLOYEE_TASK_3',
    'EMPLOYEE_TASK_4'
)
```

That is how one query can monitor four Tasks.

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

The Tasks are scheduled:

```sql
SCHEDULE = '1 MINUTE'
```

So we know that executions should occur approximately every minute.

The query generates the next five expected times **for each Task**.

For example:

```text
EMPLOYEE_TASK_1 | UPCOMING | 01:24 AM IST
EMPLOYEE_TASK_1 | UPCOMING | 01:25 AM IST
EMPLOYEE_TASK_1 | UPCOMING | 01:26 AM IST
EMPLOYEE_TASK_1 | UPCOMING | 01:27 AM IST
EMPLOYEE_TASK_1 | UPCOMING | 01:28 AM IST
EMPLOYEE_TASK_2 | UPCOMING | 01:24 AM IST
EMPLOYEE_TASK_2 | UPCOMING | 01:25 AM IST
...
```

These are **expected schedule times calculated by our query**.

They are not historical Task executions.

That distinction is important.

---

# 📊 Step 15 — Example Monitoring Output

You may see something conceptually similar to:

```text
TASK_NAME        STATUS      SCHEDULED TIME     START TIME         COMPLETED TIME
--------------------------------------------------------------------------------------
EMPLOYEE_TASK_1  SUCCESS     01:21:00 AM IST    01:21:01 AM IST    01:21:02 AM IST
EMPLOYEE_TASK_2  SUCCESS     01:21:00 AM IST    01:21:01 AM IST    01:21:02 AM IST
EMPLOYEE_TASK_3  SUCCESS     01:21:00 AM IST    01:21:01 AM IST    01:21:03 AM IST
EMPLOYEE_TASK_4  SUCCESS     01:21:00 AM IST    01:21:02 AM IST    01:21:03 AM IST
EMPLOYEE_TASK_1  UPCOMING    01:22:00 AM IST    NULL               NULL
EMPLOYEE_TASK_2  UPCOMING    01:22:00 AM IST    NULL               NULL
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

One Task failing does **not** stop the other three. Each Task has its own history row.

---

# 📁 Step 16 — Verify the Exported Files

After the Tasks have executed, check all four stages:

```sql
LIST @CUSTOMER_EXPORT_STAGE_1;
LIST @CUSTOMER_EXPORT_STAGE_2;
LIST @CUSTOMER_EXPORT_STAGE_3;
LIST @CUSTOMER_EXPORT_STAGE_4;
```

Stage 1 should hold files similar to:

```text
employee_data_1_export_20260930_012100.csv
employee_data_1_export_20260930_012200.csv
employee_data_1_export_20260930_012300.csv
```

Stage 2 should hold the matching `employee_data_2_...` files, and so on.

The filename changes because we generate it using:

```sql
CURRENT_TIMESTAMP()
```

---

# 🛑 Step 17 — Suspend the Tasks

When you finish practicing, stop the scheduled executions:

```sql
ALTER TASK EMPLOYEE_TASK_1 SUSPEND;
ALTER TASK EMPLOYEE_TASK_2 SUSPEND;
ALTER TASK EMPLOYEE_TASK_3 SUSPEND;
ALTER TASK EMPLOYEE_TASK_4 SUSPEND;
```

Verify:

```sql
SHOW TASKS LIKE 'EMPLOYEE_TASK_%';
```

All four Tasks should now be suspended.

### Why should we suspend them?

Because otherwise all four Tasks continue to execute according to their schedule.

With four Tasks running every minute, suspending them matters **four times as much** as in the single Task practice.

---

# 🔄 Step 18 — Resume the Tasks Again

Whenever you want to practice again:

```sql
ALTER TASK EMPLOYEE_TASK_1 RESUME;
ALTER TASK EMPLOYEE_TASK_2 RESUME;
ALTER TASK EMPLOYEE_TASK_3 RESUME;
ALTER TASK EMPLOYEE_TASK_4 RESUME;
```

Then verify:

```sql
SHOW TASKS LIKE 'EMPLOYEE_TASK_%';
```

The scheduler is enabled again for all four Tasks.

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

You can also give each Task a **different** schedule. For example Task 1 every minute and Task 2 every hour:

```text
EMPLOYEE_TASK_1  →  SCHEDULE = '1 MINUTE'
EMPLOYEE_TASK_2  →  SCHEDULE = '1 HOUR'
```

Each Task is scheduled on its own, so they do not need to match.

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

This lifecycle is the same for one Task or for four Tasks. You simply repeat it per Task.

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
EMPLOYEE_DATA_1
    ↓
EMPLOYEE_STREAM
    ↓
EMPLOYEE_TASK_1
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

### 7. How do several Tasks run at the same time?

```text
Each Task has its own schedule and its own objects.
One Task per table, one stage per Task.
```

### 8. What does a Stream do?

```text
Tracks changes in table data.
```

### 9. What does a Task do?

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
ALTER TASK EMPLOYEE_TASK_1 SUSPEND;
```

This stops future scheduled executions.

---

## Q4. How do you start the Task again?

```sql
ALTER TASK EMPLOYEE_TASK_1 RESUME;
```

---

## Q5. How can you check Task execution history?

> We can use `INFORMATION_SCHEMA.TASK_HISTORY()` to check Task executions, status, scheduled time, start time, completion time, and errors. We can filter it to one Task by name, or keep several Tasks with a `WHERE NAME IN (...)` filter.

---

## Q6. What is the difference between Task and Stream?

> A Stream tracks what data changed, while a Task determines when SQL or processing should run.

---

## Q7. Why did we use `EXECUTE IMMEDIATE`?

> We used it because the `COPY INTO` statement contains a dynamically generated filename, so the SQL statement needs to be constructed and executed dynamically.

---

## Q8. Can several Tasks run at the same time?

> Yes. Each Task is scheduled on its own, so four Tasks on a 1 minute schedule all run every minute. They are independent, so one Task failing does not stop the others.

---

# 🔥 Final Architecture

The complete pipeline can now be understood as:

```text
     📋 EMPLOYEE_DATA_1    📋 EMPLOYEE_DATA_2    📋 EMPLOYEE_DATA_3    📋 EMPLOYEE_DATA_4
              │                     │                     │                     │
              │                     │                     │                     │
           5 Records             5 Records             5 Records             5 Records
              │                     │                     │                     │
              ↓                     ↓                     ↓                     ↓
     ⚡ EMPLOYEE_TASK_1     ⚡ EMPLOYEE_TASK_2     ⚡ EMPLOYEE_TASK_3     ⚡ EMPLOYEE_TASK_4
              │                     │                     │                     │
              └─────────────────────┴──────────┬──────────┴─────────────────────┘
                                               │
                                        ⏰ Every 1 Minute
                                               │
                                               ↓
                                     📝 Generate Filename
                                               │
                                               ↓
                                           COPY INTO
                                               │
                     ┌───────────────┬─────────┴───────┬───────────────┐
                     ↓               ↓                 ↓               ↓
           📦 STAGE_1        📦 STAGE_2        📦 STAGE_3        📦 STAGE_4
                     │               │                 │               │
                     ↓               ↓                 ↓               ↓
                  📄 CSV          📄 CSV            📄 CSV          📄 CSV
                     └───────────────┴─────────┬───────┴───────────────┘
                                               │
                                               ↓
                                        📊 TASK HISTORY
                                               │
                              ┌────────────────┼────────────────┐
                              ↓                ↓                ↓
                          ✅ SUCCESS       ❌ FAILED       🔄 RUNNING
                                               │
                                               ↓
                                       🔍 Execution Details
                                               │
                              ┌────────────────┼────────────────┐
                              ↓                ↓                ↓
                            DATE             TIME           DURATION
                             IST              IST
                                               │
                                               ↓
                                        🔮 NEXT 5
                                       EXPECTED RUNS
                                        FOR EACH TASK
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

And for the multi version:

```text
1 Table   →  1 Stage  →  1 Task
4 Tables  →  4 Stages →  4 Tasks
```

### 🎯 One-line summary

> **Snowflake Task = automatically execute SQL at a defined time or based on a dependency, while Task History lets us monitor those executions. With four Tasks and four Stages, the same pattern simply runs four times in parallel.**
