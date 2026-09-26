# 02) OVERWRITE Mode

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [../01) input files/](../01%29%20input%20files/) | The five CSVs used by this exercise |

Overview of all four modes: [21) Spark Read and Write — Write Modes](../00%29%20README.md)

## 🎯 What `overwrite` Does

> **Whatever already sits at the output path is deleted first, then the new data is written in its place.**

```text
output already exists  →  delete it  →  write the new data
output does not exist  →  just write the new data
```

---

## Step 1 — Create the Volume

Create a volume for this exercise:

```text
overwrite_volume
```

Inside it, keep an `input/` folder and an empty `output/` folder:

```text
overwrite_volume/
│
├── input/
│   ├── employees_1.csv
│   ├── employees_2.csv
│   ├── employees_3.csv
│   ├── employees_4.csv
│   └── employees_5.csv
│
└── output/
```

Upload all five CSVs into `input/`.

> 📌 Replace `workspace.default` in the paths below with your own catalog and schema if they are named differently.

---

## Step 2 — Create the Notebook

Create a Databricks notebook named `02_csv_overwrite`, with **two cells**.

---

## 🟢 Cell 1 — READ

```python
from pyspark.sql import SparkSession

df = spark.read.csv(
    "/Volumes/workspace/default/overwrite_volume/input/employees_1.csv",
    header=True,
    inferSchema=True
)

df.show()
df.printSchema()
```

```text
CSV → spark.read.csv() → DataFrame
```

---

## 🟠 Cell 2 — WRITE

Now write that DataFrame using **overwrite**:

```python
df.write \
    .mode("overwrite") \
    .option("header", True) \
    .csv("/Volumes/workspace/default/overwrite_volume/output/")
```

### Read syntax

```python
df = spark.read.csv("INPUT_PATH", header=True, inferSchema=True)
```

### Write syntax

```python
df.write \
    .mode("overwrite") \
    .option("header", True) \
    .csv("OUTPUT_PATH")
```

---

## 🔥 The Experiment

Once `employees_1.csv` works, **do not change the output path** — only change the input file in Cell 1, then re-run Cell 1 → Cell 2.

| Run | Input in Cell 1 | Records in `output/` |
| --- | --------------- | -------------------- |
| 1 | `employees_1.csv` | 5 → **1–5** |
| 2 | `employees_2.csv` | 5 → **6–10**, and 1–5 is deleted |
| 3 | `employees_3.csv` | 5 → **11–15** |
| 4 | `employees_4.csv` | 5 → **16–20** |
| 5 | `employees_5.csv` | 5 → **21–25** |

The flow is the same every run:

```text
employees_2.csv → READ → df → OVERWRITE → output/ = 6–10
```

So after every run the output holds **5 records, never 25**. The previous output is replaced, not added to.

> ⚠️ Use `overwrite` on purpose. If you point it at a folder that already holds real data, that data is gone.

---

## 📂 About the Output Files

Spark writes a DataFrame as a **directory containing part files**, not as one CSV with your original filename:

```text
output/
├── _SUCCESS
└── part-00000-....csv
```

`part-00000-....csv` is the real data. `_SUCCESS`, `_started` and `_committed` are Spark's internal commit metadata.

> 📌 Add `.coalesce(1)` before `.write` to force a single part file instead of one per partition.
