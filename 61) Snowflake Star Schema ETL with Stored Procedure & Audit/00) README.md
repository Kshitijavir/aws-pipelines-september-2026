# 61) Snowflake — Star Schema ETL with Stored Procedure & Audit

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [input files/](input%20files/) | `customer_sales.csv` — the source data loaded into the staging table |

## 🎯 Goal

This pipeline follows the same architecture, with the **audit design** fixed. We will track:

* Staging records
* Dimension records
* Fact records
* Start time
* End time
* Duration
* Status
* Reconciliation status
* Error message

And one important point:

> **SP2 is created first, but SP1 is executed first.**

The reason is that **SP1 contains `CALL SP_LOAD_STAR_SCHEMA()`**, so SP2 must already exist when Snowflake compiles SP1. This is only **creation order**, not execution order.

---

## 🗺️ Final Architecture

```text
                 CSV FILE
                    │
                    ▼
             ┌─────────────┐
             │    STAGE    │
             └──────┬──────┘
                    │
                    │ CALL SP1
                    ▼
             ┌─────────────┐
             │     SP1     │
             │ Stage Load  │
             └──────┬──────┘
                    │
                    ▼
           ┌─────────────────┐
           │ CUSTOMER_STAGING│
           └────────┬────────┘
                    │
                    ▼
              AUDIT SP1
                    │
                    ▼
             ┌─────────────┐
             │     SP2     │
             │ Star Schema │
             └──────┬──────┘
                    │
              ┌─────┴─────┐
              ▼           ▼
        DIM_CUSTOMER   FACT_SALES
              │           │
              └─────┬─────┘
                    ▼
                 AUDIT
```

---

## 🗄️ Step 1 — Create the Database

```sql
CREATE DATABASE SNOWFLAKE_STAR_SCHEMA_PRACTICE;

USE DATABASE SNOWFLAKE_STAR_SCHEMA_PRACTICE;

CREATE SCHEMA STAR_SCHEMA;

USE SCHEMA STAR_SCHEMA;
```

---

## ⚙️ Step 2 — Create the Warehouse

```sql
CREATE WAREHOUSE STAR_WH
    WAREHOUSE_SIZE = XSMALL;

USE WAREHOUSE STAR_WH;
```

---

## 📄 Step 3 — Create the File Format

```sql
CREATE FILE FORMAT CUSTOMER_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';
```

---

## 📥 Step 4 — Create the Stage

```sql
CREATE STAGE CUSTOMER_STAGE
    FILE_FORMAT = CUSTOMER_CSV_FORMAT;
```

Source file: [input files/customer_sales.csv](input%20files/customer_sales.csv)

Upload it manually from Snowsight as `customer_sales.csv`, then:

```sql
LIST @CUSTOMER_STAGE;
```

You should see:

```text
customer_stage/customer_sales.csv
```

---

## 📋 Step 5 — Create the Staging Table

This receives the raw CSV data.

```sql
CREATE TABLE CUSTOMER_STAGING (
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    CITY          VARCHAR(100),
    COUNTRY       VARCHAR(100),
    PRODUCT       VARCHAR(100),
    QUANTITY      NUMBER,
    UNIT_PRICE    NUMBER,
    ORDER_DATE    DATE
);
```

---

## 📋 Step 6 — Create the Customer Dimension

```sql
CREATE TABLE DIM_CUSTOMER (
    CUSTOMER_KEY  NUMBER AUTOINCREMENT,
    CUSTOMER_ID   NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    CITY          VARCHAR(100),
    COUNTRY       VARCHAR(100)
);
```

### 📋 Example

```text
CUSTOMER_KEY | CUSTOMER_ID
-------------+------------
1            | 1001
2            | 1002
3            | 1003
```

`CUSTOMER_KEY` is the **surrogate key**.

---

## 📋 Step 7 — Create the Fact Table

```sql
CREATE TABLE FACT_SALES (
    SALES_KEY    NUMBER AUTOINCREMENT,
    CUSTOMER_KEY NUMBER,
    PRODUCT      VARCHAR(100),
    QUANTITY     NUMBER,
    UNIT_PRICE   NUMBER,
    TOTAL_AMOUNT NUMBER,
    ORDER_DATE   DATE
);
```

Relationship:

```text
DIM_CUSTOMER
     │
     │ CUSTOMER_KEY
     ▼
FACT_SALES
```

---

## 📋 Step 8 — Create the Audit Table

This time we'll make the audit table according to your actual requirement.

```sql
CREATE TABLE AUDIT_LOG (
    AUDIT_ID NUMBER AUTOINCREMENT,

    PIPELINE_NAME  VARCHAR(100),
    PROCEDURE_NAME VARCHAR(100),

    START_TIME       TIMESTAMP,
    END_TIME         TIMESTAMP,
    DURATION_SECONDS NUMBER,

    STAGING_RECORDS      NUMBER,
    DIM_CUSTOMER_RECORDS NUMBER,
    FACT_SALES_RECORDS   NUMBER,

    RECONCILIATION_STATUS VARCHAR(30),

    STATUS VARCHAR(30),

    ERROR_MESSAGE VARCHAR(1000),

    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
```

Now we can track:

```text
SP1
-------------------------
Staging Records
Start Time
End Time
Duration
Status


SP2
-------------------------
Staging Records
Dimension Records
Fact Records
Reconciliation
Start Time
End Time
Duration
Status
```

---

## ⬆️ Step 9 — Upload the CSV to the Stage

Source file: [input files/customer_sales.csv](input%20files/customer_sales.csv)

Upload it to `CUSTOMER_STAGE`, then:

```sql
LIST @CUSTOMER_STAGE;
```

---

## ⚠️ Step 10 — Important: Create SP2 First

This is where you were getting the error.

### 💡 Why SP2 First?

SP1 contains:

```sql
CALL SP_LOAD_STAR_SCHEMA();
```

Therefore, when Snowflake compiles SP1, `SP_LOAD_STAR_SCHEMA` needs to already exist.

So:

```text
CREATION ORDER

SP2
 ↓
SP1
```

But execution is:

```text
EXECUTION ORDER

SP1
 ↓
SP2
```

**You do NOT run SP2 first.**

You only run:

```sql
CALL SP_LOAD_STAGING();
```

Then SP1 automatically calls SP2.

---

## ⚙️ Step 11 — Create SP2 First

SP2 performs:

```text
CUSTOMER_STAGING
       │
       ├──────────► DIM_CUSTOMER
       │
       └──────────► FACT_SALES
```

Use this corrected version:

```sql
CREATE OR REPLACE PROCEDURE SP_LOAD_STAR_SCHEMA()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE

    START_TIME TIMESTAMP;
    END_TIME TIMESTAMP;

    STAGING_COUNT NUMBER;
    DIM_COUNT NUMBER;
    FACT_COUNT NUMBER;

    RECON_STATUS VARCHAR;

BEGIN

    START_TIME := CURRENT_TIMESTAMP();

    ------------------------------------------------
    -- STEP 1: Count staging records
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :STAGING_COUNT
    FROM CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 2: Load Customer Dimension
    ------------------------------------------------

    INSERT INTO DIM_CUSTOMER
    (
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CITY,
        COUNTRY
    )
    SELECT DISTINCT
        CUSTOMER_ID,
        CUSTOMER_NAME,
        EMAIL,
        CITY,
        COUNTRY
    FROM CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 3: Load Fact Table
    ------------------------------------------------

    INSERT INTO FACT_SALES
    (
        CUSTOMER_KEY,
        PRODUCT,
        QUANTITY,
        UNIT_PRICE,
        TOTAL_AMOUNT,
        ORDER_DATE
    )
    SELECT
        D.CUSTOMER_KEY,
        S.PRODUCT,
        S.QUANTITY,
        S.UNIT_PRICE,
        S.QUANTITY * S.UNIT_PRICE,
        S.ORDER_DATE
    FROM CUSTOMER_STAGING S
    JOIN DIM_CUSTOMER D
        ON S.CUSTOMER_ID = D.CUSTOMER_ID;


    ------------------------------------------------
    -- STEP 4: Count Dimension
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :DIM_COUNT
    FROM DIM_CUSTOMER;


    ------------------------------------------------
    -- STEP 5: Count Fact
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :FACT_COUNT
    FROM FACT_SALES;


    ------------------------------------------------
    -- STEP 6: Reconciliation
    ------------------------------------------------

    IF (STAGING_COUNT = FACT_COUNT) THEN
        RECON_STATUS := 'MATCH';
    ELSE
        RECON_STATUS := 'MISMATCH';
    END IF;


    ------------------------------------------------
    -- STEP 7: End Time
    ------------------------------------------------

    END_TIME := CURRENT_TIMESTAMP();


    ------------------------------------------------
    -- STEP 8: Audit SP2
    ------------------------------------------------

    INSERT INTO AUDIT_LOG
    (
        PIPELINE_NAME,
        PROCEDURE_NAME,
        START_TIME,
        END_TIME,
        DURATION_SECONDS,
        STAGING_RECORDS,
        DIM_CUSTOMER_RECORDS,
        FACT_SALES_RECORDS,
        RECONCILIATION_STATUS,
        STATUS,
        ERROR_MESSAGE
    )
    VALUES
    (
        'CUSTOMER_STAR_SCHEMA_PIPELINE',
        'SP_LOAD_STAR_SCHEMA',
        :START_TIME,
        :END_TIME,
        DATEDIFF('SECOND', :START_TIME, :END_TIME),
        :STAGING_COUNT,
        :DIM_COUNT,
        :FACT_COUNT,
        :RECON_STATUS,
        'SUCCESS',
        NULL
    );


    RETURN 'SP2 COMPLETED SUCCESSFULLY';

END;
$$;
```

Run this first.

You should get:

```text
Procedure SP_LOAD_STAR_SCHEMA successfully created
```

---

## ⚙️ Step 12 — Now Create SP1

SP1 performs:

```text
STAGE
  ↓
CUSTOMER_STAGING
  ↓
AUDIT
  ↓
SP2
```

```sql
CREATE OR REPLACE PROCEDURE SP_LOAD_STAGING()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE

    START_TIME TIMESTAMP;
    END_TIME TIMESTAMP;

    SOURCE_COUNT NUMBER;

BEGIN

    START_TIME := CURRENT_TIMESTAMP();


    ------------------------------------------------
    -- STEP 1: Clear previous staging data
    ------------------------------------------------

    TRUNCATE TABLE CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 2: Stage → Staging
    ------------------------------------------------

    COPY INTO CUSTOMER_STAGING
    FROM @CUSTOMER_STAGE
    FILE_FORMAT = (
        FORMAT_NAME = 'CUSTOMER_CSV_FORMAT'
    );


    ------------------------------------------------
    -- STEP 3: Count staging records
    ------------------------------------------------

    SELECT COUNT(*)
    INTO :SOURCE_COUNT
    FROM CUSTOMER_STAGING;


    ------------------------------------------------
    -- STEP 4: End time
    ------------------------------------------------

    END_TIME := CURRENT_TIMESTAMP();


    ------------------------------------------------
    -- STEP 5: Audit SP1
    ------------------------------------------------

    INSERT INTO AUDIT_LOG
    (
        PIPELINE_NAME,
        PROCEDURE_NAME,
        START_TIME,
        END_TIME,
        DURATION_SECONDS,
        STAGING_RECORDS,
        DIM_CUSTOMER_RECORDS,
        FACT_SALES_RECORDS,
        RECONCILIATION_STATUS,
        STATUS,
        ERROR_MESSAGE
    )
    VALUES
    (
        'CUSTOMER_STAR_SCHEMA_PIPELINE',
        'SP_LOAD_STAGING',
        :START_TIME,
        :END_TIME,
        DATEDIFF('SECOND', :START_TIME, :END_TIME),
        :SOURCE_COUNT,
        NULL,
        NULL,
        'PENDING',
        'SUCCESS',
        NULL
    );


    ------------------------------------------------
    -- STEP 6: Call SP2
    ------------------------------------------------

    CALL SP_LOAD_STAR_SCHEMA();


    RETURN 'SP1 COMPLETED SUCCESSFULLY';

END;
$$;
```

Now both procedures exist:

```sql
SHOW PROCEDURES;
```

You should find:

```text
SP_LOAD_STAGING
SP_LOAD_STAR_SCHEMA
```

---

## 🚀 Step 13 — Start the Pipeline

**Only run SP1.**

```sql
CALL SP_LOAD_STAGING();
```

Do **NOT** run:

```sql
CALL SP_LOAD_STAR_SCHEMA();
```

manually.

SP1 will automatically call it.

---

## 🔍 Step 14 — What Happens Internally?

When you execute:

```sql
CALL SP_LOAD_STAGING();
```

this happens:

```text
                 CSV
                  │
                  ▼
          ┌──────────────┐
          │ CUSTOMER_STAGE│
          └──────┬───────┘
                 │
                 ▼
                SP1
                 │
                 ▼
        CUSTOMER_STAGING
                 │
                 ▼
             AUDIT SP1
                 │
                 ▼
                SP2
                 │
          ┌──────┴──────┐
          ▼             ▼
    DIM_CUSTOMER    FACT_SALES
          │             │
          └──────┬──────┘
                 ▼
              AUDIT SP2
```

---

## ✅ Step 15 — Check the Staging Table

```sql
SELECT * FROM CUSTOMER_STAGING;
```

Expected:

```text
5 records
```

---

## ✅ Step 16 — Check the Dimension

```sql
SELECT * FROM DIM_CUSTOMER ORDER BY CUSTOMER_KEY;
```

Expected:

```text
CUSTOMER_ID
-----------
1001
1002
1003
1004
```

Why 4?

Because Rahul appears twice:

```text
1001 Rahul Laptop
1001 Rahul Mouse
```

But Rahul is **one customer**.

Therefore:

```text
STAGING = 5
DIMENSION = 4
FACT = 5
```

---

## ✅ Step 17 — Check the Fact Table

```sql
SELECT * FROM FACT_SALES ORDER BY SALES_KEY;
```

Expected 5 transactions:

```text
Rahul  → Laptop   → 75000
Priya  → Mobile   → 50000
Amit   → Monitor   → 18000
Rahul  → Mouse     → 3000
Sneha  → Keyboard  → 3000
```

---

## ✅ Step 18 — Check the Audit Log

```sql
SELECT * FROM AUDIT_LOG ORDER BY AUDIT_ID;
```

You should see approximately:

```text
PROCEDURE              STAGING   DIM   FACT   RECON
----------------------------------------------------
SP_LOAD_STAGING           5       -     -    PENDING
SP_LOAD_STAR_SCHEMA       5       4     5    MATCH
```

And you'll also have:

```text
START_TIME
END_TIME
DURATION_SECONDS
STATUS
ERROR_MESSAGE
```

---

## ⭐ The Most Important Concept

Your pipeline has **two different counts**:

```text
                    5
              STAGING RECORDS
                    │
          ┌─────────┴─────────┐
          │                   │
          ▼                   ▼
       4 CUSTOMERS        5 SALES
          │                   │
          ▼                   ▼
   DIM_CUSTOMER          FACT_SALES
```

So **4 ≠ 5 is not an error**.

The correct reconciliation is:

```text
STAGING RECORDS = FACT RECORDS
        5       =      5
             MATCH
```

And:

```text
DIM_CUSTOMER
=
DISTINCT CUSTOMER_ID

5 staging rows
→ 4 unique customers
```

---

### ⚠️ One Snowflake-Specific Point

For this **practice**, when you upload a file to an **internal Snowflake stage**, uploading the file itself does not automatically execute your stored procedure. After uploading, you start the pipeline with:

```sql
CALL SP_LOAD_STAGING();
```

So the practical flow is:

```text
Upload file
     ↓
CALL SP_LOAD_STAGING()
     ↓
SP1
     ↓
SP2
```

Later, if we want to automate the trigger, we can add Snowflake scheduling/event mechanisms. But for this pipeline, we're keeping the focus on **Stored Procedure → Star Schema → Audit → Reconciliation**.

### 🔑 Remember

**Creation:**

```text
SP2 → SP1
```

because SP1 references SP2.

**Execution:**

```text
SP1 → SP2
```

because SP1 is the master procedure.

**Run only:**

```sql
CALL SP_LOAD_STAGING();
```

This version is the clean practical implementation of the architecture you described.
