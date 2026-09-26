# 21) Spark Read and Write — Write Modes

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [01) input files/](01%29%20input%20files/) | Five CSVs, 5 employees each — `1–5`, `6–10`, `11–15`, `16–20`, `21–25` |
| [02) overwrite mode/](02%29%20overwrite%20mode/00%29%20README.md) | `overwrite` — replace whatever is already there |
| [03) append mode/](03%29%20append%20mode/00%29%20README.md) | `append` — add new files next to the old ones |
| [04) error mode/](04%29%20error%20mode/00%29%20README.md) | `error` / `errorifexists` — fail if the path exists |
| [05) ignore mode/](05%29%20ignore%20mode/00%29%20README.md) | `ignore` — skip silently if the path exists |

Every CSV has the same columns — `employee_id, name, job_role, city, salary` — and 5 rows.

## 🎯 Goal

Read one CSV into a DataFrame, write it with each of Spark's four write modes, then re-run the **same write** against the **same output path** using the next CSV. The second run is where the modes differ:

```text
employees_1.csv → output = 1–5
employees_2.csv → output = 6–10   ... but what happened to 1–5?
```

## 🧠 The Four Modes

| Mode | Alias | Output path does **not** exist | Output path **already** exists |
| ---- | ----- | ------------------------------ | ------------------------------ |
| `overwrite` | — | Writes ✅ | Deletes the old data, writes the new data 🔄 |
| `append` | — | Writes ✅ | Adds new `part-` files alongside the old ones ➕ |
| `error` | `errorifexists` | Writes ✅ | Fails the job with `PATH_ALREADY_EXISTS` ❌ |
| `ignore` | — | Writes ✅ | Does nothing at all — no error, no new data ⏭️ |

`error` and `errorifexists` are the same mode, and `error` is the **default** when no `.mode()` is given.

## 🔁 The Read / Write Shape Used in Every Exercise

```python
df = spark.read.csv("INPUT_PATH", header=True, inferSchema=True)

df.write \
    .mode("overwrite") \
    .option("header", True) \
    .csv("OUTPUT_PATH")
```

## 📊 End Result After Writing Each CSV to the Same Path

| Mode | After `1–5`, then `6–10`, … up to `21–25` |
| ---- | ----------------------------------------- |
| `overwrite` | Last file only — 5 records |
| `append` | All records kept — 25 in total, spread across several `part-` files |
| `error` | First file only — the second write crashes, so nothing after it runs |
| `ignore` | First file only — every later write is silently skipped |

## 📂 Why the Output Is a Folder, Not a `.csv` File

Spark writes a DataFrame as a **directory** holding `part-00000-….csv` plus metadata such as `_SUCCESS`. That is normal. `.option("header", True)` puts the header inside the part file, and `.coalesce(1)` forces a single part file instead of one per partition.

> 📌 Each exercise uses its own volume (`overwrite_volume`, `append_volume`, `error_volume`, `ignore_volume`) so the modes never interfere with each other.
