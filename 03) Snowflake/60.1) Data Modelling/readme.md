# 🏛️ Fact Table and Dimension Table

## 1️⃣ What is Data Modelling?
**Data modelling** means designing how data should be **stored, organized, and connected** 🧩 in a database or data warehouse.

In a Data Warehouse, we commonly use:

- 🟦 **Fact Tables**
- 🟩 **Dimension Tables**

The basic idea is:

```
                 DATA
                  │
          ┌───────┴───────┐
          ↓               ↓
     DIMENSION           FACT
       TABLE              TABLE
```

---

# 2️⃣ What is a Fact Table?
A **Fact Table** stores the **main data that we want to measure or analyze** 📊.

It normally contains:

- 🔢 Numbers
- 📏 Measurements
- 💰 Amounts
- 🧮 Counts
- 🔗 IDs that connect to Dimension tables

### 🧾 Common Fact Table columns

| Fact Data | Example |
|---|---|
| Salary | 60000 |
| Price | 5000 |
| Quantity | 10 |
| Sales Amount | 50000 |
| Profit | 10000 |
| Discount | 2000 |
| Treatment Cost | 25000 |
| Working Hours | 160 |
| Marks | 85 |
| Insurance Amount | 20000 |

### ⚠️ Important
A Fact table usually contains **foreign keys** 🔗 to Dimension tables.

For example:

```
employee_id
department_id
city_id
job_id
```

These IDs tell us **which Dimension record belongs to that Fact record** 🎯.

---

# 3️⃣ What is a Dimension Table?
A **Dimension Table** stores **descriptive information** 📝.

It tells us details about the data in the Fact table.

Dimension tables commonly contain:

- 🏷️ Names
- 🗂️ Categories
- 📍 Locations
- 🔡 Types
- 📄 Descriptions
- 📅 Dates
- ✨ Other attributes

### 🧾 Common Dimension columns

| Dimension Data | Example |
|---|---|
| Employee Name | Rahul |
| Customer Name | Priya |
| Product Name | iPhone |
| Department | IT |
| Job Title | Data Engineer |
| City | Bangalore |
| State | Karnataka |
| Country | India |
| Gender | Male |
| Customer Type | Premium |
| Course | BCA |
| Doctor | Dr. Amit |
| Hospital | Apollo |
| Disease | Diabetes |

### 🧠 Easy way to remember

```
FACT
= Numbers / Measurements 📊

DIMENSION
= Details / Description 📝
```

Another easy way:

```
FACT       → How much? / How many? 💰
DIMENSION  → Who? / What? / Where? / When? 🔍
```

---

# 4️⃣ Simple Example
Let's start with a **normal Employee table** 👨‍💼.

Before creating Fact and Dimension tables, all the data may be present in one table.

## 📋 Normal Employee Table

| employee_id | employee_name | department | city | job_title | salary | bonus |
|---|---|---|---|---|---|---|
| 101 | Rahul | IT | Bangalore | Data Engineer | 60000 | 5000 |
| 102 | Priya | HR | Mumbai | HR Manager | 70000 | 7000 |
| 103 | Amit | IT | Delhi | Developer | 55000 | 4000 |

This is our **source/normal table** 📦.

Now we need to split this data into Dimension and Fact tables ✂️.

---

# 5️⃣ Identify the Dimensions
Look at the columns:

```
employee_id
employee_name
department
city
job_title
salary
bonus
```

We can identify:

### 👤 Employee details

```
employee_id
employee_name
```

### 🏢 Department details

```
department
```

### 📍 Location details

```
city
```

### 💼 Job details

```
job_title
```

### 🔢 Numeric data

```
salary
bonus
```

So we can create:

```
DIM_EMPLOYEE
DIM_DEPARTMENT
DIM_CITY
DIM_JOB
FACT_EMPLOYEE
```

---

# 6️⃣ Create DIM_EMPLOYEE
This table stores employee information 👤.

### 🟩 DIM_EMPLOYEE

| employee_id | employee_name |
|---|---|
| E01 | Rahul |
| E02 | Priya |
| E03 | Amit |

Here:

```
employee_id → Primary Key 🔑
```

---

# 7️⃣ Create DIM_DEPARTMENT
This table stores department information 🏢.

### 🟩 DIM_DEPARTMENT

| department_id | department |
|---|---|
| D01 | IT |
| D02 | HR |

Here:

```
department_id → Primary Key 🔑
```

---

# 8️⃣ Create DIM_CITY
This table stores city information 📍.

### 🟩 DIM_CITY

| city_id | city |
|---|---|
| C01 | Bangalore |
| C02 | Mumbai |
| C03 | Delhi |

Here:

```
city_id → Primary Key 🔑
```

---

# 9️⃣ Create DIM_JOB
This table stores job information 💼.

### 🟩 DIM_JOB

| job_id | job_title |
|---|---|
| J01 | Data Engineer |
| J02 | HR Manager |
| J03 | Developer |

Here:

```
job_id → Primary Key 🔑
```

---

# 🔟 Create FACT_EMPLOYEE
Now we create the Fact table 📊.

The Fact table contains:

- 🔗 IDs from the Dimensions
- 🔢 Numeric/measurable data

### 🟦 FACT_EMPLOYEE

| employee_id | department_id | city_id | job_id | salary | bonus |
|---|---|---|---|---|---|
| E01 | D01 | C01 | J01 | 60000 | 5000 |
| E02 | D02 | C02 | J02 | 70000 | 7000 |
| E03 | D01 | C03 | J03 | 55000 | 4000 |

Notice that the Fact table does **not** store:

```
Rahul
IT
Bangalore
Data Engineer
```

Instead, it stores:

```
E01
D01
C01
J01
```

These IDs connect the Fact table to the Dimension tables 🔗.

---

# 1️⃣1️⃣ How Fact and Dimension Tables Are Connected
The relationship looks like this:

```
                    DIM_EMPLOYEE
                 ┌─────────────────┐
                 │ employee_id PK  │
                 │ employee_name   │
                 └────────┬────────┘
                          │
                          │ employee_id
                          │
                          ▼
                   FACT_EMPLOYEE
          ┌────────────────────────────┐
          │ employee_id FK             │
          │ department_id FK           │
          │ city_id FK                 │
          │ job_id FK                  │
          │ salary                     │
          │ bonus                      │
          └──────┬─────────┬───────────┘
                 │         │
          ┌──────┘         └──────┐
          ▼                       ▼
   DIM_DEPARTMENT             DIM_CITY
   ┌───────────────┐       ┌───────────────┐
   │ department_id │       │ city_id       │
   │ department    │       │ city          │
   └───────────────┘       └───────────────┘

                         │
                         ▼
                     DIM_JOB
                  ┌─────────────┐
                  │ job_id      │
                  │ job_title   │
                  └─────────────┘
```

---

# 1️⃣2️⃣ Primary Key and Foreign Key
This is very important ⭐.

### 🔑 Primary Key
A **Primary Key (PK)** uniquely identifies a record in a table.

Example:

```
DIM_EMPLOYEE

employee_id PK
```

```
E01
E02
E03
```

Every ID is unique ✅.

---

### 🔗 Foreign Key
A **Foreign Key (FK)** is used to connect one table to another table.

For example:

```
DIM_EMPLOYEE

employee_id
E01
E02
E03
```

The Fact table contains:

```
FACT_EMPLOYEE

employee_id
E01
E02
E03
```

So:

```
DIM_EMPLOYEE.employee_id
            ↓
FACT_EMPLOYEE.employee_id
```

The same concept applies to:

```
department_id
city_id
job_id
```

---

# 1️⃣3️⃣ Complete Structure
Our final Data Warehouse model looks like this:

```
                       DIM_EMPLOYEE
                       ┌───────────┐
                       │ employee  │
                       │ employee  │
                       │ name      │
                       └─────┬─────┘
                             │
                             │
                             ▼
                       FACT_EMPLOYEE
                  ┌─────────────────────┐
                  │ employee_id         │
                  │ department_id       │
                  │ city_id             │
                  │ job_id              │
                  │ salary              │
                  │ bonus               │
                  └───┬─────┬─────┬─────┘
                      │     │     │
             ┌────────┘     │     └────────┐
             ▼              ▼              ▼
       DIM_DEPARTMENT    DIM_CITY       DIM_JOB
       ┌─────────────┐  ┌───────────┐  ┌───────────┐
       │ department  │  │ city      │  │ job_title │
       └─────────────┘  └───────────┘  └───────────┘
```

This type of design is commonly called a **Star Schema** ⭐ because the Fact table is in the center and Dimension tables are around it.

---

# 1️⃣4️⃣ How to Identify Fact and Dimension
When you receive a normal table, follow these steps 🪜.

### 🪜 Step 1 — Look at the columns
Example:

```
employee_id
employee_name
department
city
job_title
salary
bonus
```

### 🪜 Step 2 — Find descriptive information
Ask:

> "Is this column describing something?" 🤔

Examples:

```
employee_name
department
city
job_title
```

These can go into **Dimension tables** 🟩.

### 🪜 Step 3 — Find measurable/numeric data
Ask:

> "Is this value something we can measure?" 📏

Examples:

```
salary
bonus
quantity
price
profit
cost
```

These can go into the **Fact table** 🟦.

### 🪜 Step 4 — Create IDs
Create keys 🔑 for the Dimensions:

```
employee_id
department_id
city_id
job_id
```

### 🪜 Step 5 — Put those IDs into the Fact table
The Fact table uses those IDs as **Foreign Keys** 🔗.

---

# 1️⃣5️⃣ Another Simple Example — Student
Normal table 🎓:

| student_id | student_name | gender | city | course | age | marks |
|---|---|---|---|---|---|---|
| 101 | Rahul | Male | Bangalore | BCA | 20 | 85 |
| 102 | Priya | Female | Mumbai | BSc IT | 21 | 92 |
| 103 | Amit | Male | Delhi | BCA | 19 | 78 |

Possible Dimensions:

```
DIM_STUDENT
DIM_GENDER
DIM_CITY
DIM_COURSE
```

Fact:

```
FACT_STUDENT
```

Example:

| student_id | gender_id | city_id | course_id | age | marks |
|---|---|---|---|---|---|
| S01 | G01 | C01 | CO01 | 20 | 85 |
| S02 | G02 | C02 | CO02 | 21 | 92 |
| S03 | G03 | C03 | CO03 | 19 | 78 |

Again:

```
Dimensions → Details 📝

Fact → IDs + Numbers 🔗🔢
```

---

# 1️⃣6️⃣ Healthcare Example
The same concept works in healthcare 🏥.

Normal table:

| patient_id | patient_name | age | gender | city | disease | doctor | treatment_cost |
|---|---|---|---|---|---|---|---|
| 101 | Rahul | 45 | Male | Bangalore | Diabetes | Dr. Amit | 25000 |
| 102 | Priya | 32 | Female | Mumbai | Fever | Dr. Sneha | 8000 |
| 103 | Amit | 58 | Male | Delhi | Heart Disease | Dr. Raj | 75000 |

Possible Dimensions:

```
DIM_PATIENT
DIM_GENDER
DIM_CITY
DIM_DISEASE
DIM_DOCTOR
```

Fact:

```
FACT_TREATMENT
```

Fact table could contain:

```
patient_id
gender_id
city_id
disease_id
doctor_id
age
treatment_cost
```

---

# 1️⃣7️⃣ Quick Revision
⚡

### 🟦 FACT TABLE

```
FACT = Numbers / Measurements 📊

Examples:

salary
price
quantity
profit
revenue
cost
discount
marks
age
treatment_cost
working_hours
```

### 🟩 DIMENSION TABLE

```
DIMENSION = Details / Description 📝

Examples:

employee_name
customer_name
student_name
product_name
department
city
state
country
gender
course
doctor
hospital
disease
job_title
```

### 🔗 Relationship

```
DIMENSION
    │
    │ Primary Key 🔑
    ▼
FACT TABLE
    │
    │ Foreign Key 🔗
    ▼
Other Dimensions
```

### ⭐ Most important thing to remember

> 🟩 **Dimension tables tell us about the data.**

> 🟦 **Fact tables store the measurable data and connect to the Dimensions using keys.**

```
              DIMENSIONS
          "Who / What / Where" 🔍
                  │
                  │ IDs 🔗
                  ▼
                FACT
        "Numbers / Measurements" 📊
```

This is the basic concept you need before moving into **Star Schema, Snowflake Schema, and Data Warehouse modelling** 🚀.
