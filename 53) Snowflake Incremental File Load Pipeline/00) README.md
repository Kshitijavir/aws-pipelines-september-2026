# 53) Snowflake — Incremental File Load Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [input files/](input%20files/) | `sales_01_initial.csv`, `sales_02_incremental.csv`, `sales_03_incremental.csv` |

## 🎯 Goal

Now we move to a **very important Snowflake concept: Incremental Loading**.

The idea is:

```text
Day 1
CSV 1 → Stage → Table
                ↓
              3 rows

Day 2
CSV 2 → Stage → Table
                ↓
         only new 3 rows

Day 3
CSV 3 → Stage → Table
                ↓
         only new 3 rows
```

Instead of loading everything from scratch every time, we keep adding **new files / new data**.

---

## 📥 Input Files

Source folder: [input files/](input%20files/)

```text
sales_01_initial.csv
sales_02_incremental.csv
sales_03_incremental.csv
```

Each contains 3 records.

So total:

```text
3 + 3 + 3 = 9 records
```

---

## 🏗️ Pipeline Architecture

```text
sales_01_initial.csv
         ↓
       Stage
         ↓
       Table
         ↓
       3 rows


sales_02_incremental.csv
         ↓
       Stage
         ↓
     COPY INTO
         ↓
    + 3 new rows
         ↓
       6 rows


sales_03_incremental.csv
         ↓
       Stage
         ↓
     COPY INTO
         ↓
    + 3 new rows
         ↓
       9 rows
```

---

## 🗄️ Step 1 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_INCREMENTAL_PRACTICE;

USE DATABASE SNOWFLAKE_INCREMENTAL_PRACTICE;
```

---

## 📂 Step 2 — Create the Schema

```sql
CREATE SCHEMA INCREMENTAL_SCHEMA;

USE SCHEMA INCREMENTAL_SCHEMA;
```

---

## ⚙️ Step 3 — Create the Warehouse

```sql
CREATE WAREHOUSE INCREMENTAL_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE INCREMENTAL_WH;
```

---

## 📋 Step 4 — Create the Table

```sql
CREATE TABLE SALES (
    ORDER_ID   NUMBER,
    ORDER_DATE DATE,
    CITY       VARCHAR(100),
    PRODUCT    VARCHAR(100),
    QUANTITY   NUMBER,
    AMOUNT     NUMBER
);
```

Check it:

```sql
DESC TABLE SALES;
```

---

## 📄 Step 5 — Create the File Format

```sql
CREATE FILE FORMAT SALES_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    DATE_FORMAT = 'YYYY-MM-DD';
```

---

## 📥 Step 6 — Create the Internal Stage

```sql
CREATE STAGE SALES_STAGE
    FILE_FORMAT = SALES_CSV_FORMAT;
```

Check it:

```sql
SHOW STAGES;
```

---

## ⬆️ Step 7 — Upload Only the First File

From [input files/](input%20files/), take:

```text
sales_01_initial.csv
```

Upload it into the stage `SALES_STAGE`, then confirm it arrived:

```sql
LIST @SALES_STAGE;
```

You should see:

```text
sales_01_initial.csv
```

---

## 🚚 Step 8 — Load the First File

```sql
COPY INTO SALES
FROM @SALES_STAGE;
```

Check the rows:

```sql
SELECT * FROM SALES ORDER BY ORDER_ID;
```

And the count:

```sql
SELECT COUNT(*) FROM SALES;
```

Expected:

```text
3
```

---

## ➕ Step 9 — Now Add the Second File

Do **not** remove the first file.

Upload:

```text
sales_02_incremental.csv
```

Now the stage contains:

```text
SALES_STAGE
│
├── sales_01_initial.csv
└── sales_02_incremental.csv
```

Run:

```sql
LIST @SALES_STAGE;
```

---

## 🔁 Step 10 — Run COPY INTO Again

This is the important part.

```sql
COPY INTO SALES
FROM @SALES_STAGE;
```

You might think:

> "Won't Snowflake load `sales_01_initial.csv` again?"

**No.** Snowflake keeps track of the files it has already loaded, and skips a previously loaded file when it encounters the same staged file again.

```text
sales_01_initial.csv            sales_02_incremental.csv
         ↓                                  ↓
   already loaded                         new file
         ↓                                  ↓
       SKIP                                LOAD
```

Now check:

```sql
SELECT COUNT(*) FROM SALES;
```

Expected:

```text
6
```

---

## 🔍 Step 11 — Check the Data

```sql
SELECT * FROM SALES ORDER BY ORDER_ID;
```

You should have:

```text
4001
4002
4003
4004
4005
4006
```

---

## ➕ Step 12 — Add the Third File

Now upload:

```text
sales_03_incremental.csv
```

Now the stage holds:

```text
SALES_STAGE
│
├── sales_01_initial.csv     ← already loaded
├── sales_02_incremental.csv ← already loaded
└── sales_03_incremental.csv ← NEW
```

Run:

```sql
COPY INTO SALES
FROM @SALES_STAGE;
```

Then:

```sql
SELECT COUNT(*) FROM SALES;
```

Expected:

```text
9
```

---

## 🕘 Step 13 — See Which Files Were Loaded

Run:

```sql
SELECT
    FILE_NAME,
    STATUS,
    ROW_COUNT,
    LAST_LOAD_TIME
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'SNOWFLAKE_INCREMENTAL_PRACTICE.INCREMENTAL_SCHEMA.SALES',
        START_TIME => DATEADD(DAY, -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME;
```

You should see the three files and their load information.

This is very useful for understanding **which files Snowflake actually loaded**.

---

## 🧠 Step 14 — The Key Concept

The important thing here is **not** just `COPY INTO`.

It's understanding Snowflake's **load metadata / file tracking**.

Conceptually:

```text
              Stage
                │
      ┌─────────┼─────────┐
      ↓         ↓         ↓
    File 1    File 2    File 3
      │         │         │
      ↓         ↓         ↓
    Loaded    Loaded     New
      │         │         │
      └─────────┴─────────┘
                          │
                          ↓
                        Table
```

When you execute:

```sql
COPY INTO SALES
FROM @SALES_STAGE;
```

Snowflake checks the staged files and avoids loading files it recognizes as already loaded.

---

## ⚠️ Important Real-World Point

Incremental loading based on **file tracking** is different from true CDC.

For example:

```text
File 1
1001 Rahul 5000
```

Later someone changes the record:

```text
1001 Rahul 7000
```

and puts another file containing:

```text
1001 Rahul 7000
```

That doesn't automatically mean Snowflake will update the existing row.

You need a different mechanism for that:

* `MERGE`
* `Streams`
* `CDC`

We'll cover those later.

---

## 🎯 What You Learned in Pipeline 53

You now understand:

* Incremental file loading
* Multiple files arriving over time
* Stage retaining previous files
* `COPY INTO`
* Snowflake's loaded-file tracking
* `COPY_HISTORY`
* Difference between **new file loading** and **record-level updates**

