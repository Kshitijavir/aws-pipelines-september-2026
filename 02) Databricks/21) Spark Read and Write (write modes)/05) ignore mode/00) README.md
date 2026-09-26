# 05) IGNORE Mode

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [../01) input files/](../01%29%20input%20files/) | The five CSVs used by this exercise |

Overview of all four modes: [21) Spark Read and Write — Write Modes](../00%29%20README.md)

## 🎯 What `ignore` Does

> **If the output path already exists, Spark skips the write completely. No error, no overwrite, no new data.**

```text
output already exists  →  ignore the write  →  existing data untouched
output does not exist  →  write normally
```

Compared with `error`: both refuse to touch existing data, but `error` **fails the job** while `ignore` **ends successfully having done nothing**.

---

## Step 1 — Create the Volume

Create a separate volume:

```text
ignore_volume
```

Structure:

```text
ignore_volume/
│
├── input/
│   ├── employees_1.csv
│   ├── employees_2.csv
│   ├── employees_3.csv
│   ├── employees_4.csv
│   └── employees_5.csv
```

> ⚠️ Do **not** create `output/` manually. Spark creates it during the first write — that is what lets the second run detect it and skip.

> 📌 Replace `workspace.default` in the paths below with your own catalog and schema if they are named differently.

---

## Step 2 — Create the Notebook

Create a Databricks notebook named `05_csv_ignore`, with **two cells**.

---

## 🟢 Cell 1 — READ

```python
from pyspark.sql import SparkSession

df = spark.read.csv(
    "/Volumes/workspace/default/ignore_volume/input/employees_1.csv",
    header=True,
    inferSchema=True
)

df.show()
df.printSchema()
```

You should see:

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
    .mode("ignore") \
    .option("header", True) \
    .csv("/Volumes/workspace/default/ignore_volume/output/")
```

### Read syntax

```python
df = spark.read.csv("INPUT_PATH", header=True, inferSchema=True)
```

### Write syntax

```python
df.write \
    .mode("ignore") \
    .option("header", True) \
    .csv("OUTPUT_PATH")
```

---

## 🔥 The Experiment

### Run 1 — writes

`output/` does not exist yet, so `ignore` behaves like a normal write:

```text
output doesn't exist  →  IGNORE allows it  →  Spark writes  →  SUCCESS ✅
```

```text
output/
├── part-00000-....csv     →  1–5
└── _SUCCESS
```

### Run 2 — skipped

Now change **only the input file** in Cell 1 to `employees_2.csv`, run Cell 1, then run the **same** write cell again:

```python
df = spark.read.csv(
    "/Volumes/workspace/default/ignore_volume/input/employees_2.csv",
    header=True,
    inferSchema=True
)

df.show()
```

Cell 1 happily shows `6 7 8 9 10`. But Cell 2 produces:

```text
NO ERROR ❌
NO NEW DATA ❌
NO OVERWRITE ❌
```

Spark sees that `output/` already exists and skips the write silently. The job still reports **success**.

| Run | Input in Cell 1 | Output path | Result |
| --- | --------------- | ----------- | ------ |
| 1 | `employees_1.csv` | missing | writes `1–5` ✅ |
| 2 | `employees_2.csv` | exists | skipped — `output/` still `1–5` ⏭️ |
| 3 | `employees_3.csv` | exists | skipped again — still `1–5` ⏭️ |

> ⚠️ `ignore` fails **quietly**. You get a green run and no new data, which is easy to miss in a scheduled job. Prefer `error` when you actually want to be told something is wrong.

---

## 🧠 All Four Modes Side by Side

| Mode | Output doesn't exist | Output already exists | Remember it as |
| ---- | -------------------- | --------------------- | -------------- |
| `overwrite` | Write ✅ | Replace 🔄 | "Replace it." |
| `append` | Write ✅ | Add new files ➕ | "Add another output file." |
| `error` | Write ✅ | Error ❌ | "Stop! It already exists." |
| `ignore` | Write ✅ | Do nothing ⏭️ | "Already exists? Okay, skip it." |

> ⚠️ Do not confuse `ignore` with the accumulated approach in [03) append mode](../03%29%20append%20mode/00%29%20README.md). There, `1–5` + `6–10` becomes `1–10`. With `ignore`, the second write is skipped, so the output stays exactly `1–5`.

---

## 🎯 The Practice Steps

1. Delete `ignore_volume/output` if you created it manually — only `input/` should exist:

   ```text
   ignore_volume/
   └── input/
       ├── employees_1.csv
       ├── employees_2.csv
       ├── employees_3.csv
       ├── employees_4.csv
       └── employees_5.csv
   ```

2. Read `employees_1.csv` → `1–5`
3. Write with `.mode("ignore")` → `output/` = `1–5`
4. Read `employees_2.csv` → `6–10`
5. Write with `.mode("ignore")` again → `output/` is **still** `1–5`

No error, no overwrite, no append.

---

## 📂 About the Output Files

```text
output/
├── _SUCCESS
└── part-00000-....csv
```

`part-00000-....csv` holds the data. `_SUCCESS` is Spark's commit marker — its presence is exactly how Spark knows the folder is a finished dataset.
