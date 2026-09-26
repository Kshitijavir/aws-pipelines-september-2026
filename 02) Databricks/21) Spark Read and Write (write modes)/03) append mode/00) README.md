# 03) APPEND Mode

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [00) README.md](00%29%20README.md) | This explanation |
| [../01) input files/](../01%29%20input%20files/) | The five CSVs used by this exercise |

Overview of all four modes: [21) Spark Read and Write — Write Modes](../00%29%20README.md)

## 🎯 What `append` Does

> **If the output path exists, the new data is added as extra files next to the old ones. Nothing is deleted.**

```text
output already exists  →  add new part files  →  old data + new data
output does not exist  →  just write the new data
```

The catch: native `append` gives you **more files**, not one bigger file. If you want a single accumulated CSV, use the Cell 2 approach below — the two are compared further down.

---

## Step 1 — Create the Volume

```text
append_volume/
│
├── input/
│   ├── employees_1.csv
│   ├── employees_2.csv
│   ├── employees_3.csv
│   ├── employees_4.csv
│   └── employees_5.csv
│
└── output/          ← leave this empty
```

> 📌 Replace `workspace.default` in the paths below with your own catalog and schema if they are named differently.

---

## Step 2 — Create the Notebook

Create a Databricks notebook named `03_csv_append`, with **two cells**.

---

## 🟢 Cell 1 — READ

```python
from pyspark.sql import SparkSession

df = spark.read.csv(
    "/Volumes/workspace/default/append_volume/input/employees_1.csv",
    header=True,
    inferSchema=True
)

df.show()
```

First run this and make sure you get:

```text
1
2
3
4
5
```

---

## 🟠 Cell 2 — ACCUMULATE INTO ONE CSV

Native `append` would leave a growing pile of part files, so Cell 2 unions the existing output with the new data and rewrites it:

```python
output_path = "/Volumes/workspace/default/append_volume/output/"

# Check whether output directory contains files
files = dbutils.fs.ls(output_path)

data_files = [
    file.path
    for file in files
    if file.name.startswith("part-")
]

if len(data_files) > 0:

    # Read existing accumulated data
    existing_df = spark.read.csv(
        output_path,
        header=True,
        inferSchema=True
    )

    # Add new data to existing data
    final_df = existing_df.unionByName(df)

else:

    # First file
    final_df = df

# Rewrite the accumulated data
final_df.coalesce(1) \
    .write \
    .mode("overwrite") \
    .option("header", True) \
    .csv(output_path)
```

---

## 🔥 The Experiment

Change the input file in Cell 1, then re-run Cell 1 → Cell 2 each time.

| Run | Input in Cell 1 | What Cell 2 does | Records in `output/` |
| --- | --------------- | ---------------- | -------------------- |
| 1 | `employees_1.csv` | no part file yet, so `final_df = df` | 5 → **1–5** |
| 2 | `employees_2.csv` | reads `1–5`, then `unionByName(df)` | 10 → **1–10** |
| 3 | `employees_3.csv` | reads `1–10`, then `unionByName(df)` | 15 → **1–15** |
| 4 | `employees_4.csv` | reads `1–15`, then `unionByName(df)` | 20 → **1–20** |
| 5 | `employees_5.csv` | reads `1–20`, then `unionByName(df)` | 25 → **1–25** |

The logic inside Cell 2:

```text
output already has a part file?
        ↓
       YES
        ↓
read the existing output
        ↓
unionByName() with the new df
        ↓
overwrite the output with the combined data
```

---

## ⚠️ This Is Not Native `append`

The folder is about accumulating data, so Cell 2 unions and rewrites. That is different from Spark's own append mode:

| Approach | What the output looks like |
| -------- | -------------------------- |
| `.mode("append")` | Old part files **plus** new part files — 5 files after 5 runs |
| Cell 2 above | One part file rewritten each run, always holding the full accumulated data |

Native append syntax, for comparison:

```python
df.write \
    .mode("append") \
    .option("header", True) \
    .csv("/Volumes/workspace/default/append_volume/output/")
```

Run that five times and `output/` holds five part files. Spark still reads them together as one 25-record dataset — the data is the same, only the file layout differs.

---

## 📂 About the Output Files

`.coalesce(1)` asks Spark to produce **one data part file** for this practice:

```text
output/
├── _SUCCESS
├── _started_...
├── _committed_...
└── part-00000-....csv
```

`part-00000-....csv` is the real data and holds the full accumulated set — `1–5`, then `1–10`, then `1–15`, and so on. `_SUCCESS`, `_started` and `_committed` are Spark's internal commit metadata.
