-- ============================================================
-- 60.1) Data Modelling - 03) Stored Procedure Basics
-- All the SQL for this practice, in one file.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- Two tables:  STUDENT -> COLLEGE
--
-- 1. We load 30 records into STUDENT.
-- 2. First we copy them into COLLEGE by hand (without an SP).
-- 3. Then we save the copy logic inside a Stored Procedure.
-- 4. Then we run the SP with one short CALL line.
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- The big box that holds everything for this practice
-- ============================================================

CREATE DATABASE IF NOT EXISTS STORED_PROCEDURE_PRACTICE;

-- Uses this database for the next statements
USE DATABASE STORED_PROCEDURE_PRACTICE;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- A folder that keeps this practice's tables together
-- ============================================================

CREATE SCHEMA IF NOT EXISTS SP_SCHEMA;

-- Uses this schema for the next statements
USE SCHEMA SP_SCHEMA;


-- ============================================================
-- STEP 3. CREATE THE STUDENT TABLE
-- The data arrives here first
-- Both tables have the same five columns on purpose
-- ============================================================

CREATE OR REPLACE TABLE STUDENT (
    STUDENT_ID   INT,
    STUDENT_NAME VARCHAR,
    AGE          INT,
    COLLEGE_NAME VARCHAR,
    COURSE       VARCHAR
);

-- Shows the table (it is empty now)
SELECT * FROM STUDENT;


-- ============================================================
-- STEP 4. CREATE THE COLLEGE TABLE
-- The data is copied here
-- Same five columns as STUDENT. No keys and no checks on purpose
-- ============================================================

CREATE OR REPLACE TABLE COLLEGE (
    STUDENT_ID   INT,
    STUDENT_NAME VARCHAR,
    AGE          INT,
    COLLEGE_NAME VARCHAR,
    COURSE       VARCHAR
);

-- Shows the table (it is empty now)
SELECT * FROM COLLEGE;


-- ============================================================
-- STEP 5. LOAD 1 - 5 RECORDS
-- After this: STUDENT = 5 rows, COLLEGE = 0 rows
-- ============================================================

INSERT INTO STUDENT VALUES
(1, 'Rahul', 20, 'ABC College', 'BCA'),
(2, 'Amit', 21, 'XYZ College', 'BSc IT'),
(3, 'Priya', 20, 'ABC College', 'BCA'),
(4, 'Sneha', 22, 'PQR College', 'BCom'),
(5, 'Rohit', 21, 'XYZ College', 'BSc IT');

SELECT COUNT(*) AS STUDENT_ROWS FROM STUDENT;
SELECT COUNT(*) AS COLLEGE_ROWS FROM COLLEGE;


-- ============================================================
-- STEP 6. LOAD 2 - 5 RECORDS
-- After this: STUDENT = 10 rows
-- ============================================================

INSERT INTO STUDENT VALUES
(6, 'Karan', 20, 'ABC College', 'BCA'),
(7, 'Neha', 21, 'PQR College', 'BCom'),
(8, 'Akash', 22, 'XYZ College', 'BSc IT'),
(9, 'Pooja', 20, 'ABC College', 'BCA'),
(10, 'Vikas', 21, 'PQR College', 'BCom');


-- ============================================================
-- STEP 7. LOAD 3 - 5 RECORDS
-- After this: STUDENT = 15 rows
-- ============================================================

INSERT INTO STUDENT VALUES
(11, 'Anjali', 20, 'ABC College', 'BCA'),
(12, 'Suresh', 22, 'XYZ College', 'BSc IT'),
(13, 'Meena', 21, 'PQR College', 'BCom'),
(14, 'Arjun', 20, 'ABC College', 'BCA'),
(15, 'Nisha', 22, 'XYZ College', 'BSc IT');


-- ============================================================
-- STEP 8. LOAD 4 - 5 RECORDS
-- After this: STUDENT = 20 rows
-- ============================================================

INSERT INTO STUDENT VALUES
(16, 'Manoj', 21, 'PQR College', 'BCom'),
(17, 'Divya', 20, 'ABC College', 'BCA'),
(18, 'Ramesh', 22, 'XYZ College', 'BSc IT'),
(19, 'Kavya', 21, 'PQR College', 'BCom'),
(20, 'Ajay', 20, 'ABC College', 'BCA');


-- ============================================================
-- STEP 9. LOAD 5 - 5 RECORDS
-- After this: STUDENT = 25 rows
-- ============================================================

INSERT INTO STUDENT VALUES
(21, 'Varun', 22, 'XYZ College', 'BSc IT'),
(22, 'Swati', 20, 'ABC College', 'BCA'),
(23, 'Naveen', 21, 'PQR College', 'BCom'),
(24, 'Riya', 20, 'ABC College', 'BCA'),
(25, 'Deepak', 22, 'XYZ College', 'BSc IT');


-- ============================================================
-- STEP 10. LOAD 6 - 5 RECORDS
-- After this: STUDENT = 30 rows, COLLEGE = 0 rows
-- ============================================================

INSERT INTO STUDENT VALUES
(26, 'Pavan', 21, 'PQR College', 'BCom'),
(27, 'Asha', 20, 'ABC College', 'BCA'),
(28, 'Vijay', 22, 'XYZ College', 'BSc IT'),
(29, 'Isha', 21, 'PQR College', 'BCom'),
(30, 'Sameer', 20, 'ABC College', 'BCA');

-- Shows all 30 rows in STUDENT
SELECT * FROM STUDENT ORDER BY STUDENT_ID;

SELECT COUNT(*) AS STUDENT_ROWS FROM STUDENT;
SELECT COUNT(*) AS COLLEGE_ROWS FROM COLLEGE;


-- ============================================================
-- STEP 11. SCENARIO 1 - WITHOUT A STORED PROCEDURE
-- We write the copy logic by hand, and then we run it.
-- It copies every row from STUDENT into COLLEGE.
--
-- After this: STUDENT = 30 rows, COLLEGE = 30 rows
-- ============================================================

INSERT INTO COLLEGE
SELECT *
FROM STUDENT;

SELECT COUNT(*) AS STUDENT_ROWS FROM STUDENT;
SELECT COUNT(*) AS COLLEGE_ROWS FROM COLLEGE;


-- ============================================================
-- STEP 12. TOMORROW - 5 MORE RECORDS ARRIVE
-- We insert them into STUDENT (rows 31 to 35).
-- Then we must REMEMBER the copy logic and run it AGAIN by hand.
--
-- This is the problem. Every new load needs the same manual work.
-- ============================================================

INSERT INTO STUDENT VALUES
(31, 'Raj', 21, 'ABC College', 'BCA'),
(32, 'Priti', 20, 'XYZ College', 'BSc IT'),
(33, 'Mohit', 22, 'PQR College', 'BCom'),
(34, 'Sakshi', 21, 'ABC College', 'BCA'),
(35, 'Nitin', 20, 'XYZ College', 'BSc IT');

-- The same copy logic, written by hand again
INSERT INTO COLLEGE
SELECT *
FROM STUDENT;

SELECT COUNT(*) AS STUDENT_ROWS FROM STUDENT;
SELECT COUNT(*) AS COLLEGE_ROWS FROM COLLEGE;

-- NOTE
-- This copy statement moves ALL rows every time, not only the new ones.
-- So COLLEGE now holds the old rows again plus the new rows.
-- That is on purpose here. We are learning the SP idea only.
-- All the extra checks come later.


-- ============================================================
-- STEP 13. SCENARIO 2 - CREATE THE STORED PROCEDURE
-- We save the copy logic inside ONE Stored Procedure.
-- After this, we never type the copy logic again.
--
-- The SP does only this:
--   1. copies every row from STUDENT into COLLEGE
--   2. sends back a short message
--
-- No duplicate check. No error handling. On purpose. Keep it simple.
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_LOAD_STUDENT_TO_COLLEGE()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN

    INSERT INTO COLLEGE
    SELECT *
    FROM STUDENT;

    RETURN 'STUDENT DATA LOADED INTO COLLEGE';

END;
$$;


-- ============================================================
-- STEP 14. RUN THE STORED PROCEDURE
-- No long SQL. Just one short line.
-- The SP runs the copy logic that is saved inside it.
--
-- ⚠️ This SP adds rows. Every CALL copies all rows again.
--    Run it when you want to see the SP work.
-- ============================================================

CALL SP_LOAD_STUDENT_TO_COLLEGE();

SELECT COUNT(*) AS STUDENT_ROWS FROM STUDENT;
SELECT COUNT(*) AS COLLEGE_ROWS FROM COLLEGE;


-- ============================================================
-- STEP 15. RUN THE SAME SP AGAIN (OPTIONAL)
-- This shows the important point:
-- 1st CALL -> COLLEGE = 30 rows
-- 2nd CALL -> COLLEGE = 60 rows (the same rows added again)
--
-- For this practice that is fine. We are not doing duplicate checks yet.
--
-- 🚫 The CALL below is left switched off on purpose.
--    Why : it adds the same rows a second time and makes duplicates.
--    Uncomment it only when you want to see the 60 rows.
-- ============================================================

-- CALL SP_LOAD_STUDENT_TO_COLLEGE();


-- ============================================================
-- STEP 16. CHECK EVERYTHING
-- ============================================================

SELECT * FROM STUDENT ORDER BY STUDENT_ID;

SELECT * FROM COLLEGE ORDER BY STUDENT_ID;

SELECT COUNT(*) AS STUDENT_ROWS FROM STUDENT;
SELECT COUNT(*) AS COLLEGE_ROWS FROM COLLEGE;


-- ============================================================
-- STEP 17. SEE THE SP IN THE DATABASE
-- Lists the procedures in this schema
-- ============================================================

SHOW PROCEDURES;
