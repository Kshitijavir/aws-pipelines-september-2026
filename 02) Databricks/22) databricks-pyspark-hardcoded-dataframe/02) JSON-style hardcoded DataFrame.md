```python
from pyspark.sql import SparkSession

# Create Spark Session
spark = SparkSession.builder.appName("Hardcoded JSON DataFrame Practice").getOrCreate()

# Hardcoded JSON-style data
data = [
    {
        "employee_id": 1,
        "employee_name": "Kshitij",
        "job_role": "Data Engineer"
    },
    {
        "employee_id": 2,
        "employee_name": "Rahul",
        "job_role": "AWS Engineer"
    },
    {
        "employee_id": 3,
        "employee_name": "Amit",
        "job_role": "Data Analyst"
    }
]

# Create DataFrame
df = spark.createDataFrame(data)

# Display DataFrame
display(df)
```

---

### Second one = List + Dictionary ✅

```text
data = [
    {
        "employee_id": 1,
        "employee_name": "Kshitij",
        "job_role": "Data Engineer"
    },
    {
        "employee_id": 2,
        "employee_name": "Rahul",
        "job_role": "AWS Engineer"
    }
]
```

Here:

- `[...]` → **List**
- `{...}` → **Dictionary**

So:

```text
List
 ├── Dictionary
 ├── Dictionary
 └── Dictionary
```

Each dictionary represents one row.

### ⚠️ Small correction

Technically, the second one is **not JSON**.

It is:

> **List of Python Dictionaries**

It **looks like JSON**, because JSON also uses `{ key: value }` structures.

Think of it this way:

| Code | Actual type |
| ---- | ----------- |
| `[(1, "A"), (2, "B")]` | List of Tuples |
| `[{"id": 1}, {"id": 2}]` | List of Dictionaries |
| JSON file | JSON data |

For your PySpark learning, this distinction is important:

```text
Python List + Tuple
        ↓
spark.createDataFrame(data, columns)
```

and

```text
Python List + Dictionary
        ↓
spark.createDataFrame(data)
```

Both can be converted into a **Spark DataFrame**.
