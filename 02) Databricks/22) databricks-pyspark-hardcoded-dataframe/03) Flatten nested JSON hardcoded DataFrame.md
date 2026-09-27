# 22) Databricks — PySpark Flatten Nested JSON

> 📌 First understand the **concept of Flatten JSON**, then we'll do the practical.

## 🧩 What is Flatten JSON?

In real projects, JSON data is often **nested**.

For example:

```text
data = [
    {
        "employee_id": 1,
        "employee_name": "Kshitij",
        "job_role": "Data Engineer",
        "address": {
            "city": "Bangalore",
            "country": "India"
        }
    }
]
```

Here, `address` contains another object:

```text
employee
│
├── employee_id
├── employee_name
├── job_role
│
└── address
     │
     ├── city
     └── country
```

So `city` and `country` are **inside `address`**.

### What does flattening mean?

**Flattening means taking nested fields and bringing them to the top level of the DataFrame.**

Before flattening:

```text
employee_id | employee_name | job_role       | address
---------------------------------------------------------------
1           | Kshitij       | Data Engineer  | {city, country}
```

After flattening:

```text
employee_id | employee_name | job_role       | city       | country
--------------------------------------------------------------------
1           | Kshitij       | Data Engineer  | Bangalore  | India
```

So simply:

```text
Nested JSON
     ↓
Flatten
     ↓
Flat DataFrame
```

---

## 🛠️ Practical: Hardcoded Nested JSON → Flatten → DataFrame

We will use:

- `SparkSession`
- Hardcoded Python list
- Python dictionaries
- Nested `address`
- `spark.createDataFrame()`
- `col()`
- `select()`
- `alias()`
- `display()`

> ⚠️ We will **NOT use `StructType` or `StructField`**.

### 💻 Complete code

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("Flatten JSON Practice").getOrCreate()

# Hardcoded nested JSON-style data
data = [
    {
        "employee_id": 1,
        "employee_name": "Kshitij",
        "job_role": "Data Engineer",
        "address": {
            "city": "Bangalore",
            "country": "India"
        }
    },
    {
        "employee_id": 2,
        "employee_name": "Rahul",
        "job_role": "AWS Engineer",
        "address": {
            "city": "Pune",
            "country": "India"
        }
    },
    {
        "employee_id": 3,
        "employee_name": "Amit",
        "job_role": "Data Analyst",
        "address": {
            "city": "Mumbai",
            "country": "India"
        }
    }
]

# Create DataFrame
df = spark.createDataFrame(data)

# Display original nested DataFrame
display(df)

# Flatten the nested address fields
df_flattened = df.select(
    col("employee_id"),
    col("employee_name"),
    col("job_role"),
    col("address.city").alias("city"),
    col("address.country").alias("country")
)

# Display flattened DataFrame
display(df_flattened)
```

---

## 🔍 Now Understand the Important Lines

### 1. Import `SparkSession`

```python
from pyspark.sql import SparkSession
```

Imports `SparkSession`.

We need it to work with Spark.

---

### 2. Import `col`

```python
from pyspark.sql.functions import col
```

`col()` allows us to refer to a DataFrame column.

For example:

```python
col("employee_id")
```

means:

> 💡 Give me the `employee_id` column.

For nested data:

```python
col("address.city")
```

means:

> 💡 Go inside `address` and get `city`.

---

### 3. Create Spark Session

```python
spark = SparkSession.builder.appName("Flatten JSON Practice").getOrCreate()
```

This gives us our Spark object:

```text
SparkSession
     ↓
   spark
```

We then use:

```python
spark.createDataFrame()
```

---

### 4. Hardcoded nested data

```python
data = [
    {
        "employee_id": 1,
        "employee_name": "Kshitij",
        "job_role": "Data Engineer",
        "address": {
            "city": "Bangalore",
            "country": "India"
        }
    }
]
```

This is:

```text
List
 ↓
Dictionary
 ↓
Nested Dictionary
```

The important part is:

```text
"address": {
    "city": "Bangalore",
    "country": "India"
}
```

`address` itself contains another dictionary.

That's our **nested JSON-style structure**.

---

### 5. Create DataFrame

```python
df = spark.createDataFrame(data)
```

Spark converts our Python data into a Spark DataFrame.

Conceptually:

```text
Python List + Dictionaries
          ↓
spark.createDataFrame()
          ↓
Spark DataFrame
```

---

### 6. Display original DataFrame

```python
display(df)
```

This lets you see the nested structure before flattening.

---

## 🔥 7. Actual Flattening

This is the most important section:

```python
df_flattened = df.select(
    col("employee_id"),
    col("employee_name"),
    col("job_role"),
    col("address.city").alias("city"),
    col("address.country").alias("country")
)
```

Let's break it down.

### Normal columns

```python
col("employee_id")
```

Gets:

```text
employee_id
```

```python
col("employee_name")
```

Gets:

```text
employee_name
```

```python
col("job_role")
```

Gets:

```text
job_role
```

### Nested columns

```python
col("address.city")
```

means:

```text
address
   ↓
city
```

And:

```python
col("address.country")
```

means:

```text
address
   ↓
country
```

---

### Why `.alias("city")`?

We write:

```python
col("address.city").alias("city")
```

because we want the output column to simply be called:

```text
city
```

Similarly:

```python
col("address.country").alias("country")
```

creates:

```text
country
```

---

## 🏁 Final Flow

```text
Hardcoded Nested JSON
          ↓
   createDataFrame()
          ↓
   Nested DataFrame
          ↓
       select()
          ↓
   address.city
   address.country
          ↓
       Flatten
          ↓
    Flat DataFrame
          ↓
      display()
```

### 🧠 Remember this simple definition

> **Flattening JSON = converting nested JSON fields into separate top-level DataFrame columns.**

And in our example:

```text
address.city
     ↓
   city

address.country
     ↓
  country
```

That's the basic **nested JSON flattening concept in PySpark**.
