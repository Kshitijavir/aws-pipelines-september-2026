-- ============================================================
-- 60.1) Data Modelling - 02) STAR Schema
-- All the SQL for this practice, in one file.
-- Paste this whole file into a Snowflake worksheet and run it.
--
-- We build one small Star Schema for customers:
--   NORMAL_CUSTOMER  -> the source table (all data in one place)
--   DIM_CUSTOMER, DIM_CITY, DIM_COUNTRY, DIM_CUSTOMER_TYPE
--   FACT_CUSTOMER    -> the center table
-- ============================================================


-- ============================================================
-- STEP 1. CREATE DATABASE
-- The big box that holds everything for this practice
-- ============================================================

CREATE DATABASE IF NOT EXISTS CUSTOMER_STAR_SCHEMA_PRACTICE;

-- Uses this database for the next statements
USE DATABASE CUSTOMER_STAR_SCHEMA_PRACTICE;


-- ============================================================
-- STEP 2. CREATE SCHEMA
-- A folder that keeps this practice's tables together
-- ============================================================

CREATE SCHEMA IF NOT EXISTS CUSTOMER_STAR_SCHEMA;

-- Uses this schema for the next statements
USE SCHEMA CUSTOMER_STAR_SCHEMA;


-- ============================================================
-- STEP 3. CREATE THE SOURCE TABLE
-- This is the normal table. All customer data sits here first
-- ============================================================

CREATE OR REPLACE TABLE NORMAL_CUSTOMER (
    CUSTOMER_ID       NUMBER,
    CUSTOMER_NAME     VARCHAR(100),
    CITY              VARCHAR(100),
    COUNTRY           VARCHAR(100),
    CUSTOMER_TYPE     VARCHAR(50),
    AGE               NUMBER
);


-- ============================================================
-- STEP 4. PUT THE SOURCE DATA IN
-- 3 customers. One row = one customer
-- ============================================================

INSERT INTO NORMAL_CUSTOMER (
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    COUNTRY,
    CUSTOMER_TYPE,
    AGE
)
VALUES
    (101, 'Rahul Sharma', 'Bangalore', 'India', 'Premium', 30),
    (102, 'Priya Singh',  'Mumbai',    'India', 'Regular', 27),
    (103, 'Amit Kumar',   'Delhi',     'India', 'Premium', 35);

-- Shows the source data
SELECT * FROM NORMAL_CUSTOMER;


-- ============================================================
-- STEP 5. CREATE DIM_CUSTOMER
-- Stores who the customer is (the name)
-- ============================================================

CREATE OR REPLACE TABLE DIM_CUSTOMER (
    CUSTOMER_ID       NUMBER,
    CUSTOMER_NAME     VARCHAR(100)
);


-- ============================================================
-- STEP 6. PUT DATA INTO DIM_CUSTOMER
-- ============================================================

INSERT INTO DIM_CUSTOMER (
    CUSTOMER_ID,
    CUSTOMER_NAME
)
VALUES
    (101, 'Rahul Sharma'),
    (102, 'Priya Singh'),
    (103, 'Amit Kumar');

-- Shows the customer details
SELECT * FROM DIM_CUSTOMER;


-- ============================================================
-- STEP 7. CREATE DIM_CITY
-- Stores where the customer lives (the city)
-- ============================================================

CREATE OR REPLACE TABLE DIM_CITY (
    CITY_ID       VARCHAR(10),
    CITY          VARCHAR(100)
);


-- ============================================================
-- STEP 8. PUT DATA INTO DIM_CITY
-- ============================================================

INSERT INTO DIM_CITY (
    CITY_ID,
    CITY
)
VALUES
    ('C01', 'Bangalore'),
    ('C02', 'Mumbai'),
    ('C03', 'Delhi');

-- Shows the cities
SELECT * FROM DIM_CITY;


-- ============================================================
-- STEP 9. CREATE DIM_COUNTRY
-- Stores the country
-- NOTE: the same country is repeated 3 times on purpose.
-- This is only for practice.
-- ============================================================

CREATE OR REPLACE TABLE DIM_COUNTRY (
    COUNTRY_ID       VARCHAR(10),
    COUNTRY          VARCHAR(100)
);


-- ============================================================
-- STEP 10. PUT DATA INTO DIM_COUNTRY
-- ============================================================

INSERT INTO DIM_COUNTRY (
    COUNTRY_ID,
    COUNTRY
)
VALUES
    ('CY01', 'India'),
    ('CY02', 'India'),
    ('CY03', 'India');

-- Shows the countries
SELECT * FROM DIM_COUNTRY;


-- ============================================================
-- STEP 11. CREATE DIM_CUSTOMER_TYPE
-- Stores the type of customer (Premium / Regular)
-- NOTE: 'Premium' is repeated on purpose. This is only for practice.
-- ============================================================

CREATE OR REPLACE TABLE DIM_CUSTOMER_TYPE (
    CUSTOMER_TYPE_ID       VARCHAR(10),
    CUSTOMER_TYPE          VARCHAR(50)
);


-- ============================================================
-- STEP 12. PUT DATA INTO DIM_CUSTOMER_TYPE
-- ============================================================

INSERT INTO DIM_CUSTOMER_TYPE (
    CUSTOMER_TYPE_ID,
    CUSTOMER_TYPE
)
VALUES
    ('CT01', 'Premium'),
    ('CT02', 'Regular'),
    ('CT03', 'Premium');

-- Shows the customer types
SELECT * FROM DIM_CUSTOMER_TYPE;


-- ============================================================
-- STEP 13. CREATE FACT_CUSTOMER
-- This is the center table.
-- It holds the IDs (links to the dimensions) and the number (AGE).
-- No primary key and no foreign key are added on purpose.
-- ============================================================

CREATE OR REPLACE TABLE FACT_CUSTOMER (
    CUSTOMER_ID          NUMBER,
    CITY_ID              VARCHAR(10),
    COUNTRY_ID           VARCHAR(10),
    CUSTOMER_TYPE_ID     VARCHAR(10),
    AGE                  NUMBER
);


-- ============================================================
-- STEP 14. PUT DATA INTO FACT_CUSTOMER
-- Every row links to one row in each dimension table
-- ============================================================

INSERT INTO FACT_CUSTOMER (
    CUSTOMER_ID,
    CITY_ID,
    COUNTRY_ID,
    CUSTOMER_TYPE_ID,
    AGE
)
VALUES
    (101, 'C01', 'CY01', 'CT01', 30),
    (102, 'C02', 'CY02', 'CT02', 27),
    (103, 'C03', 'CY03', 'CT03', 35);

-- Shows the center table
SELECT * FROM FACT_CUSTOMER;


-- ============================================================
-- STEP 15. CHECK EVERY TABLE
-- Shows the data of every table, one by one
-- ============================================================

SELECT * FROM NORMAL_CUSTOMER;

SELECT * FROM DIM_CUSTOMER;

SELECT * FROM DIM_CITY;

SELECT * FROM DIM_COUNTRY;

SELECT * FROM DIM_CUSTOMER_TYPE;

SELECT * FROM FACT_CUSTOMER;

-- Shows all the tables in this schema
SHOW TABLES;


-- ============================================================
-- STEP 16. PRACTICE QUERY 1 - CUSTOMERS FROM BANGALORE
-- We join the fact table with two dimension tables
-- ============================================================

SELECT
    F.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    CI.CITY
FROM FACT_CUSTOMER F

INNER JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID

INNER JOIN DIM_CITY CI
    ON F.CITY_ID = CI.CITY_ID

WHERE CI.CITY = 'Bangalore';


-- ============================================================
-- STEP 17. PRACTICE QUERY 2 - FULL REPORT FOR BANGALORE
-- Same idea, but now we add all the dimension tables
-- ============================================================

SELECT
    F.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    CI.CITY,
    CO.COUNTRY,
    CT.CUSTOMER_TYPE,
    F.AGE
FROM FACT_CUSTOMER F

INNER JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID

INNER JOIN DIM_CITY CI
    ON F.CITY_ID = CI.CITY_ID

INNER JOIN DIM_CUSTOMER_TYPE CT
    ON F.CUSTOMER_TYPE_ID = CT.CUSTOMER_TYPE_ID

INNER JOIN DIM_COUNTRY CO
    ON F.COUNTRY_ID = CO.COUNTRY_ID

WHERE CI.CITY = 'Bangalore';


-- ============================================================
-- STEP 18. PRACTICE QUERY 3 - FULL REPORT FOR ALL CUSTOMERS
-- Same as Query 2, but with no WHERE line.
-- So we see every customer.
-- ============================================================

SELECT
    F.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    CI.CITY,
    CO.COUNTRY,
    CT.CUSTOMER_TYPE,
    F.AGE
FROM FACT_CUSTOMER F

INNER JOIN DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID

INNER JOIN DIM_CITY CI
    ON F.CITY_ID = CI.CITY_ID

INNER JOIN DIM_CUSTOMER_TYPE CT
    ON F.CUSTOMER_TYPE_ID = CT.CUSTOMER_TYPE_ID

INNER JOIN DIM_COUNTRY CO
    ON F.COUNTRY_ID = CO.COUNTRY_ID;


-- ============================================================
-- STEP 19. PRACTICE QUERY 4 - HOW MANY CUSTOMERS PER CITY
-- GROUP BY makes one row per city, with a count
-- ============================================================

SELECT
    CI.CITY,
    COUNT(F.CUSTOMER_ID) AS CUSTOMER_COUNT
FROM FACT_CUSTOMER F

INNER JOIN DIM_CITY CI
    ON F.CITY_ID = CI.CITY_ID

GROUP BY
    CI.CITY;


-- ============================================================
-- STEP 20. LOAD DATA AUTOMATICALLY (STORED PROCEDURE)
-- This procedure does the loading for us.
-- It reads NORMAL_CUSTOMER and fills the dimensions and the fact.
--
-- It creates the IDs by itself with ROW_NUMBER().
-- So the ID numbers can be in a different order than the
-- manual example above.
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_LOAD_CUSTOMER_DATA()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN

    -- 1. LOAD DIM_CUSTOMER
    INSERT INTO DIM_CUSTOMER (
        CUSTOMER_ID,
        CUSTOMER_NAME
    )
    SELECT DISTINCT
        CUSTOMER_ID,
        CUSTOMER_NAME
    FROM NORMAL_CUSTOMER;


    -- 2. LOAD DIM_CITY
    INSERT INTO DIM_CITY (
        CITY_ID,
        CITY
    )
    SELECT
        'C' || LPAD(
            ROW_NUMBER() OVER (ORDER BY CITY),
            2,
            '0'
        ),
        CITY
    FROM (
        SELECT DISTINCT CITY
        FROM NORMAL_CUSTOMER
    );


    -- 3. LOAD DIM_COUNTRY
    INSERT INTO DIM_COUNTRY (
        COUNTRY_ID,
        COUNTRY
    )
    SELECT
        'CY' || LPAD(
            ROW_NUMBER() OVER (ORDER BY COUNTRY),
            2,
            '0'
        ),
        COUNTRY
    FROM (
        SELECT DISTINCT COUNTRY
        FROM NORMAL_CUSTOMER
    );


    -- 4. LOAD DIM_CUSTOMER_TYPE
    INSERT INTO DIM_CUSTOMER_TYPE (
        CUSTOMER_TYPE_ID,
        CUSTOMER_TYPE
    )
    SELECT
        'CT' || LPAD(
            ROW_NUMBER() OVER (ORDER BY CUSTOMER_TYPE),
            2,
            '0'
        ),
        CUSTOMER_TYPE
    FROM (
        SELECT DISTINCT CUSTOMER_TYPE
        FROM NORMAL_CUSTOMER
    );


    -- 5. LOAD FACT_CUSTOMER
    INSERT INTO FACT_CUSTOMER (
        CUSTOMER_ID,
        CITY_ID,
        COUNTRY_ID,
        CUSTOMER_TYPE_ID,
        AGE
    )
    SELECT
        N.CUSTOMER_ID,
        C.CITY_ID,
        CO.COUNTRY_ID,
        CT.CUSTOMER_TYPE_ID,
        N.AGE
    FROM NORMAL_CUSTOMER N

    LEFT JOIN DIM_CITY C
        ON N.CITY = C.CITY

    LEFT JOIN DIM_COUNTRY CO
        ON N.COUNTRY = CO.COUNTRY

    LEFT JOIN DIM_CUSTOMER_TYPE CT
        ON N.CUSTOMER_TYPE = CT.CUSTOMER_TYPE;


    RETURN 'Customer data successfully loaded into dimensions and fact';

END;
$$;


-- 🚫 DO NOT RUN THE CALL BELOW BY HAND
-- Who runs it : you, but only when the tables are EMPTY
-- Why : it adds rows. Running it twice makes duplicate rows.
-- CALL SP_LOAD_CUSTOMER_DATA();
