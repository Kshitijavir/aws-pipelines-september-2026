# 56) Snowflake — Stream-Based Incremental Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |

## 🎯 Goal

This pipeline is where we properly learn **Snowflake Streams**.

Before building anything, let's understand the concept in very simple terms.

---

## 🔥 What is a Snowflake Stream?

A **Stream is a change tracker**.

It records the **changes that happen to a table** after the stream is created.

Think of it like:

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

A Stream does **not store a second copy of your entire table**.

Instead, it gives you information about changes such as:

```text
INSERT
UPDATE
DELETE
```

---

## 🧠 Simple Example

Suppose our table contains:

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

Now someone inserts:

```sql
INSERT INTO EMPLOYEE VALUES
(4, 'Sneha', 80000);
```

The table becomes:

```text
1 Rahul  50000
2 Priya  60000
3 Amit   70000
4 Sneha  80000
```

But the Stream lets us see:

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

The Stream captures the change.

For an update, Snowflake can expose metadata such as:

```text
METADATA$ACTION
METADATA$ISUPDATE
```

For example, conceptually:

```text
UPDATE
Old Priya row
New Priya row
```

This is extremely useful for CDC-style pipelines.

---

## 🗑️ What about DELETE?

If:

```sql
DELETE FROM EMPLOYEE
WHERE ID = 3;
```

the Stream can show that the row was deleted.

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

Without a Stream, you might have to repeatedly check:

```text
10 million records
        ↓
Find changed records
```

That's inefficient.

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

That's the important idea.

---

## ⚠️ Stream vs Stage

Don't confuse them.

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

Now let's build a complete practical pipeline.

Our architecture will be:

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

We'll specifically practice:

* Source table
* Initial data
* Stream
* Insert new record
* Update existing record
* Delete record
* Read Stream
* Process Stream
* Load changes into target table
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

Check:

```sql
SELECT * FROM EMPLOYEE_SOURCE ORDER BY EMPLOYEE_ID;
```

You should have:

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

Check:

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

But the stream has **no new changes yet** because we created it after the initial data was inserted.

That's intentional.

---

## ➕ Step 7 — Insert a New Employee

Now perform a change:

```sql
INSERT INTO EMPLOYEE_SOURCE VALUES
(7004, 'Sneha Joshi', 'IT', 78000);
```

Check the source:

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

Important metadata columns include:

```text
METADATA$ACTION
METADATA$ISUPDATE
METADATA$ROW_ID
```

For the new employee, conceptually:

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

Now you'll see the change generated by the update.

The important thing is:

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

You can see the delete information.

---

## ⚠️ Important Stream Behavior

Now comes one of the most important things to understand.

A Stream behaves somewhat like a **change queue**.

If you do:

```sql
SELECT * FROM EMPLOYEE_STREAM;
```

you are reading the stream.

But the changes aren't simply "gone" because you queried it.

The Stream's change tracking is tied to **consumption through DML**, not merely running a `SELECT`.

We'll demonstrate this properly by consuming the stream into another table.

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

We can use the Stream as the source of an `INSERT`:

```sql
INSERT INTO EMPLOYEE_TARGET
SELECT
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    DEPARTMENT,
    SALARY
FROM EMPLOYEE_STREAM;
```

Now check:

```sql
SELECT * FROM EMPLOYEE_TARGET;
```

The changed rows have been processed into the target.

---

## 🧠 But there's a problem

If we simply insert all Stream rows into the target, updates/deletes need special handling.

For a proper CDC pipeline, we normally use:

```text
Stream
   ↓
MERGE
   ↓
Target
```

And that's where Pipeline 55 and Pipeline 56 start connecting.

---

## 🔀 Step 13 — Better Stream + MERGE Pattern

Create another target table:

```sql
CREATE TABLE EMPLOYEE_FINAL (
    EMPLOYEE_ID   NUMBER,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT    VARCHAR(50),
    SALARY        NUMBER
);
```

Then conceptually:

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

This is the pattern you'll see frequently in Snowflake pipelines.

---

## 🔥 The Key Stream Columns

When querying a stream, pay attention to:

### 🏷️ `METADATA$ACTION`

Usually:

```text
INSERT
DELETE
```

### 🔁 `METADATA$ISUPDATE`

Tells you whether the change is associated with an update.

### 🆔 `METADATA$ROW_ID`

A unique identifier associated with the row/change.

For learning, run:

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

The important difference from Pipeline 53 is:

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

You should be comfortable with:

* What a Stream is
* Why Streams are used
* Creating a Stream
* Table → Stream relationship
* INSERT tracking
* UPDATE tracking
* DELETE tracking
* `METADATA$ACTION`
* `METADATA$ISUPDATE`
* `METADATA$ROW_ID`
* Consuming Stream data
* Stream + `MERGE`
* CDC-style processing

