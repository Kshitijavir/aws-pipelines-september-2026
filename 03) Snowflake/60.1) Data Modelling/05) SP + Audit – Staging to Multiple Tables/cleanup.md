# 🧹 Cleanup — 60.1) Data Modelling → 05) SP + Audit – Staging to Multiple Tables

This file removes every Snowflake object that this practice creates.
Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 60.1) Data Modelling - 05) SP + Audit - Staging to Multiple Tables
DROP PROCEDURE IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA.SP_LOAD_DATA();
DROP TABLE IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA.SP_LOAD_AUDIT;
DROP TABLE IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA.STAGING_LOAD_AUDIT;
DROP TABLE IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA.CLAIM;
DROP TABLE IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA.PROVIDER;
DROP TABLE IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA.LOCATION;
DROP TABLE IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA.PRODUCT;
DROP TABLE IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA.CUSTOMER;
DROP TABLE IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA.STAGING;
DROP SCHEMA IF EXISTS SP_AUDIT_PRACTICE.SP_AUDIT_SCHEMA;
DROP DATABASE IF EXISTS SP_AUDIT_PRACTICE;
```

## 2️⃣ Or Just Stop the Cost

This practice does **not** create a warehouse. It uses Snowflake's default one.

So there is nothing extra to suspend here.

If another practice created a warehouse of its own, stop it like this (put your own warehouse name in place of `YOUR_WH`):

```sql
-- Keeps all the objects, and stops the cost
ALTER WAREHOUSE YOUR_WH SUSPEND;
```

## 📌 Notes

- The object names are written in full (`DATABASE.SCHEMA.OBJECT`), so this file works in any session. You do not need to run `USE DATABASE` first.
- Small objects are dropped before the big object that holds them: procedure → audit tables → 5 target tables → `STAGING` → schema → database.
- `DROP SCHEMA` fails if the schema still has objects inside it. That is why the procedure and all 8 tables are dropped first. Add `CASCADE` only if you want one statement to delete everything inside the schema.
- The Stored Procedure is dropped first, because the procedure points at the tables. Dropping it first keeps every step safe to run.
- There are **8 tables** in this practice:
  `STAGING`, `STAGING_LOAD_AUDIT`, `SP_LOAD_AUDIT`, `CUSTOMER`, `PRODUCT`, `LOCATION`, `PROVIDER`, `CLAIM`.
- The tables have no keys, so the drop order of the tables does not matter here. The list above is just written from the smallest object to the biggest.
