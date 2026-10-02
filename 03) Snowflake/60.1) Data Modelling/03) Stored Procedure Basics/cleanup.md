# 🧹 Cleanup — 60.1) Data Modelling → 03) Stored Procedure Basics

This file removes every Snowflake object that the Stored Procedure practice creates.
Run the statements from top to bottom.

## 1️⃣ Drop Everything

```sql
-- 60.1) Data Modelling - 03) Stored Procedure Basics
DROP PROCEDURE IF EXISTS STORED_PROCEDURE_PRACTICE.SP_SCHEMA.SP_LOAD_STUDENT_TO_COLLEGE();
DROP TABLE IF EXISTS STORED_PROCEDURE_PRACTICE.SP_SCHEMA.COLLEGE;
DROP TABLE IF EXISTS STORED_PROCEDURE_PRACTICE.SP_SCHEMA.STUDENT;
DROP SCHEMA IF EXISTS STORED_PROCEDURE_PRACTICE.SP_SCHEMA;
DROP DATABASE IF EXISTS STORED_PROCEDURE_PRACTICE;
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
- Small objects are dropped before the big object that holds them: procedure → tables → schema → database.
- `DROP SCHEMA` fails if the schema still has objects inside it. That is why the procedure and the tables are dropped first. Add `CASCADE` only if you want one statement to delete everything inside the schema.
- The tables have no keys, so the drop order does not matter here. The list above is just written from the smallest object to the biggest.
- The Stored Procedure is dropped first, because a procedure can point at the tables. Dropping it first keeps every step safe to run.
