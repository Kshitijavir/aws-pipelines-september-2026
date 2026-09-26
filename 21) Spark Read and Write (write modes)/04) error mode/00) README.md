# 04) ERROR Mode

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [../01) input files/](../01%29%20input%20files/) | The five CSVs used by this exercise |

Overview of all four modes: [21) Spark Read and Write — Write Modes](../00%29%20README.md)

## 🎯 What `error` Does

> **If the output path already exists, Spark stops and throws an error instead of writing anything.**

```text
output already exists  →  fail the job  →  existing data untouched
output does not exist  →  write normally
```

This is the safe choice when you **do not want to accidentally overwrite existing data**.

> 📌 `error`, `errorifexists` and `failfast` all mean the same thing, and `error` is Spark's **default** mode when no `.mode()` is given.

---

## Step 1 — Create the Volume

Create a separate volume:

```text
error_volume
```

Structure:

```text
error_volume/
│
├── input/
│   ├── employees_1.csv
│   ├── employees_2.csv
│   ├── employees_3.csv
│   ├── employees_4.csv
│   └── employees_5.csv
```

> ⚠️ Do **not** create `output/` manually — that is the whole point of this exercise. Create only the volume and upload the CSVs into `input/`.

> 📌 Replace `workspace.default` in the paths below with your own catalog and schema if they are named differently.

---

## Step 2 — Create the Notebook

Create a Databricks notebook named `04_csv_error`, with **two cells**.

---

## 🟢 Cell 1 — READ

```python
from pyspark.sql import SparkSession

df = spark.read.csv(
    "/Volumes/workspace/default/error_volume/input/employees_1.csv",
    header=True,
    inferSchema=True
)

df.show()
```

Check the schema:

```python
df.printSchema()
```

You should get the 5 records:

```text
1
2
3
4
5
```

---

## 🟠 Cell 2 — WRITE

```python
df.write \
    .mode("error") \
    .option("header", True) \
    .csv("/Volumes/workspace/default/error_volume/output/")
```

### Read syntax

```python
df = spark.read.csv("INPUT_PATH", header=True, inferSchema=True)
```

### Write syntax

```python
df.write \
    .mode("error") \
    .option("header", True) \
    .csv("OUTPUT_PATH")
```

---

## 🔥 The Experiment

### Run 1 — succeeds

Read `employees_1.csv` with Cell 1, then run the write cell. `output/` does not exist yet, so Spark creates it:

```text
output/
└── part-00000-....csv     →  1–5
```

### Run 2 — fails

Now **change nothing**. Run the exact same write cell again. `output/` already exists, so Spark refuses:

```text
output/ already exists
        ↓
     ❌ ERROR
```

The job fails with a message like:

```text
[PATH_ALREADY_EXISTS] Path already exists
```

The exact wording varies a little between Databricks and Spark versions.

| Run | Input in Cell 1 | Output path | Result |
| --- | --------------- | ----------- | ------ |
| 1 | `employees_1.csv` | missing | writes `1–5` ✅ |
| 2 | `employees_1.csv` | exists | `PATH_ALREADY_EXISTS` ❌ |
| 3 | `employees_2.csv` | exists | fails again — `output/` only ever holds `1–5` |

> 📌 Nothing is written and nothing is deleted on a failed run. `error` is the "stop if the folder already exists" mode.

---

## 🧠 Why the Job Fails

`error` means: *"if the destination already exists, write nothing."* So the first run succeeds and **every run after that fails**, no matter which CSV Cell 1 reads:

```text
employees_2.csv → READ → df = 6–10 → WRITE → output already exists → ERROR ❌
```

The original `1–5` output stays untouched.

> ⚠️ Do not delete `output/` between runs — hitting the existing folder is the whole point of the exercise.

---

## 💡 Real-World Use

Suppose a job writes a daily folder, `output/2026-09-26/`, and accidentally runs twice:

| Mode | What the second run does |
| ---- | ------------------------ |
| `overwrite` | Replaces the first result — easy to miss |
| `append` | Adds a duplicate set of files — easy to miss |
| `error` | Fails loudly, so the duplicate run cannot touch the data |

That is why `error` is the sensible default for date-partitioned output: it turns a silent double-processing bug into a visible failure.
