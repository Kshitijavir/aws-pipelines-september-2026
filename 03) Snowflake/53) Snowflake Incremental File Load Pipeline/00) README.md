# 53) Snowflake — Incremental File Load Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [input files/](input%20files/) | `sales_01_initial.csv`, `sales_02_incremental.csv`, `sales_03_incremental.csv` |

## 🎯 Goal

Now we look at a **very important Snowflake idea: Incremental Loading**.

Here is the idea:

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

Instead of loading all the data again every time, we keep adding **new files / new data**.

---

## 📥 Input Files

Source folder: [input files/](input%20files/)

```text
sales_01_initial.csv
sales_02_incremental.csv
sales_03_incremental.csv
```

Each file has 3 records.

So the total is:

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

Check the table:

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

Check the stage:

```sql
SHOW STAGES;
```

---

## ⬆️ Step 7 — Upload Only the First File

From [input files/](input%20files/), take this file:

```text
sales_01_initial.csv
```

Upload it to the stage `SALES_STAGE`. Then check that it arrived:

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

Then check the count:

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

Upload this file:

```text
sales_02_incremental.csv
```

Now the stage holds:

```text
SALES_STAGE
│
├── sales_01_initial.csv
└── sales_02_incremental.csv
```

Run this:

```sql
LIST @SALES_STAGE;
```

---

## 🔁 Step 10 — Run COPY INTO Again

This is the part that matters most.

```sql
COPY INTO SALES
FROM @SALES_STAGE;
```

You might think:

> "Won't Snowflake load `sales_01_initial.csv` again?"

**No.** Snowflake remembers the files it has already loaded. If it sees the same staged file again, it skips it.

```text
sales_01_initial.csv            sales_02_incremental.csv
         ↓                                  ↓
   already loaded                         new file
         ↓                                  ↓
       SKIP                                LOAD
```

Now check the count:

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

You should see these order IDs:

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

Now upload this file:

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

Run this:

```sql
COPY INTO SALES
FROM @SALES_STAGE;
```

Then check the count:

```sql
SELECT COUNT(*) FROM SALES;
```

Expected:

```text
9
```

---

## 🕘 Step 13 — See Which Files Were Loaded

Run this query:

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

You should see the three files and their load details.

This helps you see **which files Snowflake really loaded**.

---

## 🧠 Step 14 — The Key Concept

The important thing here is **not** just `COPY INTO`.

It is about how Snowflake **keeps a record of which files it loaded**. This record is called load metadata.

Picture it like this:

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

When you run:

```sql
COPY INTO SALES
FROM @SALES_STAGE;
```

Snowflake looks at the files in the stage. It does not load a file it has already loaded before.

---

## ⚠️ Important Real-World Point

Incremental loading based on **file tracking** is not the same as true CDC.

CDC means tracking changes row by row.

For example:

```text
File 1
1001 Rahul 5000
```

Later, someone changes that record:

```text
1001 Rahul 7000
```

Then they put in another file that holds:

```text
1001 Rahul 7000
```

That does not mean Snowflake will update the row that is already there.

You need a different way to do that:

* `MERGE`
* `Streams`
* `CDC`

We will cover those later.

---

## 🎯 What You Learned in Pipeline 53

You now understand:

* Loading files one at a time (incremental loading)
* Many files arriving over time
* The stage keeps the older files
* `COPY INTO`
* Snowflake remembers which files it loaded
* `COPY_HISTORY`
* The difference between **loading a new file** and **updating one row**

