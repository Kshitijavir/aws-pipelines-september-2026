# 🧹 Cleanup — 60.1) Data Modelling → 02) STAR Schema

This file removes every Snowflake object that the Star Schema practice creates.
Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 60.1) Data Modelling - 02) STAR Schema practice
DROP PROCEDURE IF EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE.CUSTOMER_STAR_SCHEMA.SP_LOAD_CUSTOMER_DATA();
DROP TABLE IF EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE.CUSTOMER_STAR_SCHEMA.FACT_CUSTOMER;
DROP TABLE IF EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE.CUSTOMER_STAR_SCHEMA.DIM_CUSTOMER;
DROP TABLE IF EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE.CUSTOMER_STAR_SCHEMA.DIM_CITY;
DROP TABLE IF EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE.CUSTOMER_STAR_SCHEMA.DIM_COUNTRY;
DROP TABLE IF EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE.CUSTOMER_STAR_SCHEMA.DIM_CUSTOMER_TYPE;
DROP TABLE IF EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE.CUSTOMER_STAR_SCHEMA.NORMAL_CUSTOMER;
DROP SCHEMA IF EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE.CUSTOMER_STAR_SCHEMA;
DROP DATABASE IF EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE;
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
- Small objects are dropped before the big object that holds them: procedure → fact → dimensions → schema → database.
- `DROP SCHEMA` fails if the schema still has objects inside it. That is why the tables and the procedure are dropped first. Add `CASCADE` only if you want one statement to delete everything inside the schema.
- The `FACT_CUSTOMER` table points to the dimension tables only by values. There are no real keys, so the drop order does not matter here. The list above is just written from the smallest object to the biggest.
