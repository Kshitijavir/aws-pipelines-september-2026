# 22) Databricks — PySpark Hardcoded DataFrame

> 📌 The simplest possible PySpark exercise: hand-write the data in Python, turn it into a Spark DataFrame, and display it in Databricks. No files, no volumes, no readers — just **data → DataFrame → table**.

## 🔄 Pipeline

```text
Hardcoded Data
      ↓
Create Spark DataFrame
      ↓
Display DataFrame
```

## 💻 Complete Databricks Notebook Code

```python
from pyspark.sql import SparkSession

# Create Spark Session
spark = SparkSession.builder.appName("Hardcoded DataFrame Practice").getOrCreate()

# Hardcoded data
data = [
    (1, "Kshitij", "Data Engineer"),
    (2, "Rahul", "AWS Engineer"),
    (3, "Amit", "Data Analyst")
]

# Column names
columns = ["employee_id", "employee_name", "job_role"]

# Create DataFrame
df = spark.createDataFrame(data, columns)

# Display DataFrame
display(df)
```

## 🔍 Let's Understand Every Line

### 1️⃣ Import `SparkSession`

```python
from pyspark.sql import SparkSession
```

This imports **`SparkSession`** from PySpark.

Think of `SparkSession` as the **main entry point to Spark**.

You use it to perform operations such as:

```python
spark.createDataFrame()
spark.read.csv()
spark.read.json()
```

So:

```text
SparkSession
     ↓
    spark
     ↓
Spark operations
```

---

### 2️⃣ Create Spark Session

```python
spark = SparkSession.builder.appName("Hardcoded DataFrame Practice").getOrCreate()
```

This creates or gets a Spark session.

#### 🧱 `SparkSession.builder`

```python
SparkSession.builder
```

Starts the process of configuring a Spark session.

#### 🏷️ `.appName()`

```python
.appName("Hardcoded DataFrame Practice")
```

Gives your Spark application a name.

Here we named it:

```text
Hardcoded DataFrame Practice
```

This is mainly useful for identifying the application in Spark UI/logs.

#### ♻️ `.getOrCreate()`

```python
.getOrCreate()
```

This means:

> 💡 If a Spark session already exists, use it. Otherwise, create one.

So the complete concept is:

```text
SparkSession
     ↓
   builder
     ↓
   appName
     ↓
 getOrCreate
     ↓
   spark
```

---

### 3️⃣ Create Hardcoded Data

```python
data = [
    (1, "Kshitij", "Data Engineer"),
    (2, "Rahul", "AWS Engineer"),
    (3, "Amit", "Data Analyst")
]
```

This is simply a **Python list containing tuples**.

Think of it like a small table:

| ID | Name    | Role          |
| -: | ------- | ------------- |
|  1 | Kshitij | Data Engineer |
|  2 | Rahul   | AWS Engineer  |
|  3 | Amit    | Data Analyst  |

> ⚠️ At this point, **this is NOT a Spark DataFrame yet**.
>
> It is just Python data.

```text
Python List
     ↓
[(1, "Kshitij", "Data Engineer"),
 (2, "Rahul", "AWS Engineer"),
 (3, "Amit", "Data Analyst")]
```

---

### 4️⃣ Define Column Names

```python
columns = ["employee_id", "employee_name", "job_role"]
```

These are the names that we want for our DataFrame columns.

So:

```text
1       → employee_id
Kshitij → employee_name
Data Engineer → job_role
```

---

### 5️⃣ Create the DataFrame

⭐ This is the **most important line**:

```python
df = spark.createDataFrame(data, columns)
```

Here we tell Spark:

> 💡 Take this Python data and convert it into a Spark DataFrame using these column names.

Conceptually:

```text
Python data
     +
Column names
     ↓
spark.createDataFrame()
     ↓
Spark DataFrame
     ↓
df
```

✅ Now `df` is a Spark DataFrame.

---

### 6️⃣ Display the DataFrame

```python
display(df)
```

Databricks provides the `display()` function to show the DataFrame in a nice table format.

👀 You'll see something like:

| employee_id | employee_name | job_role      |
| ----------: | ------------- | ------------- |
|           1 | Kshitij       | Data Engineer |
|           2 | Rahul         | AWS Engineer  |
|           3 | Amit          | Data Analyst  |

---

## 🧠 One Important Concept

Notice that we **didn't write this**:

```python
SparkContext
```

and we didn't manually create:

```python
SparkContext()
```

because in Databricks, Spark is already configured for you. 🎁

For this practice, the important object is:

```python
spark
```

and you use it to create the DataFrame:

```python
df = spark.createDataFrame(data, columns)
```

### 🚀 Your First PySpark Flow

```text
                Databricks
                    │
                    ↓
            Spark Environment
                    │
                    ↓
              SparkSession
                    │
                    ↓
                  spark
                    │
                    ↓
        spark.createDataFrame()
                    │
                    ↓
             Spark DataFrame
                    │
                    ↓
               display(df)
```

> 📌 **For now, remember only these 4 things:**

1. 🚪 `SparkSession` → main entry point to Spark
2. ⚡ `spark` → SparkSession object
3. 🧱 `spark.createDataFrame()` → creates a DataFrame
4. 🖥️ `display(df)` → displays the DataFrame in Databricks
