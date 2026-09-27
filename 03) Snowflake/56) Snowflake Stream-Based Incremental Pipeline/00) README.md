# 56) Snowflake — Stream-Based Incremental Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |

## 🎯 Goal

This pipeline teaches you **Snowflake Streams**.

First, let's learn the idea in very simple words.

---

## 🔥 What is a Snowflake Stream?

A **Stream is a change tracker**.

It records the **changes made to a table** after you create the stream.

Think of it like this:

```text
EMPLOYEE_TABLE
      │
      │ INSERT / UPDATE / DELETE
      ↓
   STREAM
      │
      ↓
"Here are the rows that changed"
```

A Stream does **not save a second copy of your whole table**.

Instead, it tells you what changed. Here are the change types:

```text
INSERT
UPDATE
DELETE
```

---

## 🧠 Simple Example

Suppose our table holds:

```text
EMPLOYEE
-------------------------
ID    NAME      SALARY
1     Rahul     50000
2     Priya     60000
3     Amit      70000
```

Create a stream:

```sql
CREATE STREAM EMPLOYEE_STREAM
ON TABLE EMPLOYEE;
```

Now someone adds a row:

```sql
INSERT INTO EMPLOYEE VALUES
(4, 'Sneha', 80000);
```

The table now holds:

```text
1 Rahul  50000
2 Priya  60000
3 Amit   70000
4 Sneha  80000
```

But the Stream shows us:

```text
4 Sneha 80000
```

as a **change**.

---

## 🔄 What about UPDATE?

Suppose:

```sql
UPDATE EMPLOYEE
SET SALARY = 65000
WHERE ID = 2;
```

The Stream records the change.

For an update, Snowflake can show extra details like:

```text
METADATA$ACTION
METADATA$ISUPDATE
```

For example, in plain terms:

```text
UPDATE
Old Priya row
New Priya row
```

This helps a lot with CDC-style pipelines.

---

## 🗑️ What about DELETE?

If:

```sql
DELETE FROM EMPLOYEE
WHERE ID = 3;
```

the Stream can show that the row is gone.

So:

```text
INSERT → Stream sees INSERT
UPDATE → Stream sees UPDATE change
DELETE → Stream sees DELETE
```

---

## ⭐ Why do we need Streams?

Imagine this table has **10 million records**.

Every 10 minutes, only 500 records change.

Without a Stream, you must read the whole table again and again:

```text
10 million records
        ↓
Find changed records
```

That wastes time and money.

With a Stream:

```text
10 million record table
         │
         ↓
      Stream
         │
         ↓
Only changed records
         │
         ↓
    Process them
```

That is the main idea.

---

## ⚠️ Stream vs Stage

Do not mix them up.

### 📦 Stage

```text
Stage = Where files are stored
```

Example:

```text
CSV → Stage
```

### 🔄 Stream

```text
Stream = Tracks table changes
```

Example:

```text
Table
 ↓
INSERT / UPDATE / DELETE
 ↓
Stream
 ↓
Changed records
```

---

## ⚠️ Stream vs Table

A Stream is **not your main data table**.

Think:

```text
TABLE
↓
Actual data


STREAM
↓
Changes happening to that data
```

---

## 🔥 The Stream-Based Incremental Pipeline

Now let's build a full example pipeline.

Our design will be:

```text
                 SOURCE TABLE
                      │
                      │  INSERT / UPDATE
                      ▼
                    STREAM
                      │
                      │  Changed rows
                      ▼
                 TARGET TABLE
```

We will practice these steps:

* The source table
* The first rows of data
* The Stream
* Insert a new row
* Update an existing row
* Delete a row
* Read the Stream
* Use up the Stream rows
* Load the changes into the target table
* Understand `METADATA$ACTION`
* Understand `METADATA$ISUPDATE`

---

## 🗄️ Step 1 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_STREAM_PRACTICE;

USE DATABASE SNOWFLAKE_STREAM_PRACTICE;
```

---

## 📂 Step 2 — Create the Schema

```sql
CREATE SCHEMA STREAM_SCHEMA;

USE SCHEMA STREAM_SCHEMA;
```

---

## ⚙️ Step 3 — Create the Warehouse

```sql
CREATE WAREHOUSE STREAM_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE STREAM_WH;
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
(7001, 'Rahul Sharma', 'IT', 85000),
(7002, 'Priya Patil', 'HR', 62000),
(7003, 'Amit Verma', 'Finance', 95000);
```

Check the table:

```sql
SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;
```

You should see:

```text
7001 Rahul  IT       85000
7002 Priya  HR       62000
7003 Amit   Finance  95000
```

---

## 🔄 Step 6 — Create the Stream

Now:

```sql
CREATE STREAM EMPLOYEE_STREAM
ON TABLE EMPLOYEE_SOURCE;
```

Check the streams:

```sql
SHOW STREAMS;
```

You should see:

```text
EMPLOYEE_STREAM
```

---

## 🧠 Important

At this point:

```text
EMPLOYEE_SOURCE
        │
        ↓
EMPLOYEE_STREAM
```

But the stream has **no new changes yet**. We made the stream after the first rows were added.

That is on purpose.

---

## ➕ Step 7 — Insert a New Employee

Now make a change:

```sql
INSERT INTO EMPLOYEE_SOURCE VALUES
(7004, 'Sneha Joshi', 'IT', 78000);
```

Check the source table:

```sql
SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;
```

You now have 4 employees.

---

## 🔍 Step 8 — Read the Stream

Now:

```sql
SELECT * FROM EMPLOYEE_STREAM;
```

You should see the new change.

The important extra columns are:

```text
METADATA$ACTION
METADATA$ISUPDATE
METADATA$ROW_ID
```

For the new employee, in plain terms:

```text
EMPLOYEE_ID = 7004
METADATA$ACTION = INSERT
METADATA$ISUPDATE = FALSE
```

---

## ✏️ Step 9 — Update an Existing Employee

Now:

```sql
UPDATE EMPLOYEE_SOURCE
SET SALARY = 90000
WHERE EMPLOYEE_ID = 7001;
```

Read the stream:

```sql
SELECT * FROM EMPLOYEE_STREAM;
```

Now you see the change made by the update.

The main point is:

```text
UPDATE
  ↓
Stream captures change
```

---

## 🗑️ Step 10 — Delete an Employee

Now:

```sql
DELETE FROM EMPLOYEE_SOURCE
WHERE EMPLOYEE_ID = 7003;
```

Read:

```sql
SELECT * FROM EMPLOYEE_STREAM;
```

You can see the delete details.

---

## ⚠️ Important Stream Behavior

This is one of the most important things to know.

A Stream acts like a **queue of changes**.

If you do:

```sql
SELECT * FROM EMPLOYEE_STREAM;
```

you are reading the stream.

But the changes do not vanish just because you read them.

The stream only clears its rows when you **use them in a DML statement**. A plain `SELECT` is not enough.

We will show this by reading the stream into another table.

---

## 📋 Step 11 — Create the Target Table

```sql
CREATE TABLE EMPLOYEE_TARGET (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);
```

---

## 🚚 Step 12 — Consume the Stream

We can use the Stream as the input of an `INSERT`:

```sql
INSERT INTO EMPLOYEE_TARGET
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    DEPARTMENT,
    SALARY
FROM EMPLOYEE_STREAM;
```

Now check the target:

```sql
SELECT * FROM EMPLOYEE_TARGET;
```

The changed rows are now in the target.

---

## 🧠 But there's a problem

If we just insert every stream row, updates and deletes need special care.

For a proper CDC pipeline, we normally do this:

```text
Stream
   ↓
MERGE
   ↓
Target
```

This is where Pipeline 55 and Pipeline 56 meet.

---

## 🔀 Step 13 — Better Stream + MERGE Pattern

Create a second target table:

```sql
CREATE TABLE EMPLOYEE_FINAL (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);
```

Then, in plain terms:

```text
Source Table
     │
     │ INSERT / UPDATE / DELETE
     ↓
   Stream
     │
     ↓
    MERGE
     │
     ↓
Target Table
```

You will see this pattern often in Snowflake pipelines.

---

## 🔥 The Key Stream Columns

When you read a stream, look at:

### 🏷️ `METADATA$ACTION`

Usually:

```text
INSERT
DELETE
```

### 🔁 `METADATA$ISUPDATE`

Tells you if the change comes from an update.

### 🆔 `METADATA$ROW_ID`

A unique id for the row or change.

To practice, run:

```sql
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    DEPARTMENT,
    SALARY,
    METADATA$ACTION,
    METADATA$ISUPDATE,
    METADATA$ROW_ID
FROM EMPLOYEE_STREAM;
```

---

## 🧠 Complete Pipeline 56

```text
                EMPLOYEE_SOURCE
                       │
                       │  INSERT / UPDATE / DELETE
                       ▼
                EMPLOYEE_STREAM
                       │
                       │  Changed Records
                       ▼
                     MERGE
                       │
                       ▼
                EMPLOYEE_TARGET
```

The key difference from Pipeline 53 is:

### 📁 Pipeline 53

```text
New FILE
   ↓
COPY INTO
   ↓
Table
```

### 🔄 Pipeline 56

```text
Table Changes
     ↓
   STREAM
     ↓
Changed Rows
     ↓
  MERGE
     ↓
Target
```

---

## 🎯 What You Should Understand After Pipeline 56

You should feel at ease with:

* What a Stream is
* Why we use Streams
* How to create a Stream
* How a table and a Stream relate
* How INSERT is tracked
* How UPDATE is tracked
* How DELETE is tracked
* `METADATA$ACTION`
* `METADATA$ISUPDATE`
* `METADATA$ROW_ID`
* How to read and use Stream rows
* Stream + `MERGE`
* CDC-style processing

