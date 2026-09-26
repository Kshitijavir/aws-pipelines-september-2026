# 52) Snowflake — Table-to-Stage Export Pipeline

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |

## 🎯 Goal

Snowflake's equivalent of Redshift `UNLOAD` is `COPY INTO <location>` — the same statement used for loading, only the direction changes:

```text
Snowflake Table
      ↓
COPY INTO @Internal Stage
      ↓
CSV File
      ↓
Download to Computer
```

| Pipeline | Direction |
| -------- | --------- |
| 50 / 51 | CSV → Stage → Table |
| 52 | Table → Stage → CSV |

---

## 🗄️ Step 1 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_UNLOAD_PRACTICE;

USE DATABASE SNOWFLAKE_UNLOAD_PRACTICE;
```

---

## 📂 Step 2 — Create the Schema

```sql
CREATE SCHEMA EXPORT_SCHEMA;

USE SCHEMA EXPORT_SCHEMA;
```

---

## ⚙️ Step 3 — Create the Warehouse

```sql
CREATE WAREHOUSE EXPORT_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE EXPORT_WH;
```

---

## 📋 Step 4 — Create the Source Table

This table is the **source** for the export.

```sql
CREATE TABLE CUSTOMER_EXPORT (
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  VARCHAR(100),
    EMAIL          VARCHAR(200),
    CITY           VARCHAR(100),
    COUNTRY        VARCHAR(50),
    TOTAL_PURCHASE NUMBER
);
```

---

## ✍️ Step 5 — Insert Data

```sql
INSERT INTO CUSTOMER_EXPORT VALUES
(3001, 'Rahul Sharma', 'rahul@example.com', 'Mumbai', 'India', 75000),
(3002, 'Priya Patil', 'priya@example.com', 'Pune', 'India', 62000),
(3003, 'Amit Verma', 'amit@example.com', 'Delhi', 'India', 58000),
(3004, 'Sneha Joshi', 'sneha@example.com', 'Bengaluru', 'India', 91000),
(3005, 'Vikas Kumar', 'vikas@example.com', 'Hyderabad', 'India', 67000);
```

Verify:

```sql
SELECT *
FROM CUSTOMER_EXPORT;
```

Expected:

```text
5 rows
```

---

## 📄 Step 6 — Create the Export File Format

Here we are exporting **Snowflake → CSV**.

```sql
CREATE FILE FORMAT CUSTOMER_EXPORT_CSV_FORMAT
TYPE = 'CSV'
FIELD_DELIMITER = ','
COMPRESSION = 'NONE'
FIELD_OPTIONALLY_ENCLOSED_BY = '"';
```

### 💡 Why `COMPRESSION = 'NONE'`?

Because we want to download a normal `.csv` file that can be opened directly in Excel.

Without this, Snowflake can use compression depending on the configuration.

---

## 📥 Step 7 — Create the Internal Stage

```sql
CREATE STAGE CUSTOMER_EXPORT_STAGE
    FILE_FORMAT = CUSTOMER_EXPORT_CSV_FORMAT;
```

Check:

```sql
SHOW STAGES;
```

You should see:

```text
CUSTOMER_EXPORT_STAGE
```

---

## 🚚 Step 8 — Main Export Command

This is the most important part of Pipeline 52.

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE
FROM CUSTOMER_EXPORT;
```

The direction is:

```text
CUSTOMER_EXPORT
       │
       │ COPY INTO
       ↓
CUSTOMER_EXPORT_STAGE
```

This is Snowflake's **unload/export** operation.

---

## 🔍 Step 9 — Check the Exported File

```sql
LIST @CUSTOMER_EXPORT_STAGE;
```

You should see something similar to:

```text
customer_export_stage/data_0_0_0.csv
```

The exact filename can vary.

---

## ⬇️ Step 10 — Download the File

In Snowsight, navigate to:

```text
Data → Databases → SNOWFLAKE_UNLOAD_PRACTICE → EXPORT_SCHEMA → Stages → CUSTOMER_EXPORT_STAGE
```

You should find the exported CSV.

Download it and open it in Excel.

---

## 🏷️ Step 11 — Export With Column Headers

By default, Snowflake exports the **data rows**, but not the column names.

So this:

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE
FROM CUSTOMER_EXPORT;
```

produces:

```text
3001,Rahul Sharma,rahul@example.com,Mumbai,India,75000
3002,Priya Patil,priya@example.com,Pune,India,62000
...
```

If you want the column headers:

```text
CUSTOMER_ID,CUSTOMER_NAME,EMAIL,CITY,COUNTRY,TOTAL_PURCHASE
3001,Rahul Sharma,rahul@example.com,Mumbai,India,75000
3002,Priya Patil,priya@example.com,Pune,India,62000
...
```

use:

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE
FROM CUSTOMER_EXPORT
HEADER = TRUE;
```

### ⚠️ If the stage already contains the old file

You may get:

```text
Files already existing at the unload destination
```

because `data_0_0_0.csv` already exists.

For practice, simply clear the stage:

```sql
REMOVE @CUSTOMER_EXPORT_STAGE;
```

Then:

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE
FROM CUSTOMER_EXPORT
HEADER = TRUE;
```

Verify:

```sql
LIST @CUSTOMER_EXPORT_STAGE;
```

Then download the new file.

---

## 🎯 Step 12 — Export Only Selected Columns

You don't have to export the entire table.

For example:

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE
FROM (
    SELECT
        CUSTOMER_ID,
        CUSTOMER_NAME,
        CITY,
        TOTAL_PURCHASE
    FROM CUSTOMER_EXPORT
)
HEADER = TRUE;
```

Now the output contains only:

```text
CUSTOMER_ID
CUSTOMER_NAME
CITY
TOTAL_PURCHASE
```

---

## 🔎 Step 13 — Export Filtered Data

You can also export only specific records.

```sql
COPY INTO @CUSTOMER_EXPORT_STAGE
FROM (
    SELECT
        CUSTOMER_ID,
        CUSTOMER_NAME,
        CITY,
        TOTAL_PURCHASE
    FROM CUSTOMER_EXPORT
    WHERE TOTAL_PURCHASE > 65000
)
HEADER = TRUE;
```

Now only customers whose purchases are greater than `65000` are exported.

The flow becomes:

```text
CUSTOMER_EXPORT
       ↓
     SELECT
       ↓
    FILTER
       ↓
COPY INTO @STAGE
       ↓
     CSV
```

---

## 📦 Step 14 — Multiple Export Files

For small data you may get a single file:

```text
data_0_0_0.csv
```

For a large dataset, Snowflake can create several files:

```text
CUSTOMER_EXPORT_STAGE/
├── data_0_0_0.csv
├── data_0_1_0.csv
├── data_0_2_0.csv
└── data_0_3_0.csv
```

That is normal.

---

## 🧠 Redshift `UNLOAD` vs Snowflake

| Redshift | Snowflake |
| -------- | --------- |
| `UNLOAD` | `COPY INTO <location>` |
| Table → S3 | Table → Stage |
| Query result → S3 | Query result → Stage |
| Export files | Export files |
| Commonly uses external S3 | Can use internal or external stage |

Mental model — the same idea, a different destination:

**Redshift**

```text
Table
  ↓
UNLOAD
  ↓
S3
```

**Snowflake**

```text
Table
  ↓
COPY INTO @stage
  ↓
Internal Stage
  ↓
CSV
  ↓
Download
```

---

## 🎯 Complete Architecture

```text
                    SNOWFLAKE
                        │
                CUSTOMER_EXPORT
                        │
                        │  COPY INTO
                        ▼
              CUSTOMER_EXPORT_STAGE
                        │
                        ▼
                 data_0_0_0.csv
                        │
                        ▼
                    Download
                        │
                        ▼
                     Your PC
```

