# 📘 Databricks Job — Notebook Dependency

## 📁 Files in This Folder

| File | What It Is |
| ---- | ---------- |
| [01) README.md](01%29%20README.md) | Complete explanation of the notebook dependency job |
| [notebook_1.py](notebook_1.py) | Notebook 1 — the first task, runs on its own |
| [notebook_2.py](notebook_2.py) | Notebook 2 — the second task, depends on Notebook 1 |
| [job_definition.json](job_definition.json) | The job definition, showing the `depends_on` config between the two tasks |

> 📌 This folder is the **Databricks side only**. There is no AWS component here — no Lambda, no trust policy. It is a Databricks Job made of two notebook tasks.

---

## 1. Purpose

The purpose of this setup is to **test the dependency between two Databricks notebooks**.

There is:

* No data processing
* No input files
* No output files
* No transformations

We are only testing whether **Notebook 2 starts after Notebook 1 completes successfully**.

Both notebooks are deliberately trivial — two `print()` statements each. That is the point: with nothing to fail and no data to move, any behaviour you see in the job run is caused by the **dependency**, not by the code.

---

## 2. Notebook 1

Create a Databricks notebook with the name:

```text
notebook_1
```

### Code

[notebook_1.py](notebook_1.py)

```python
print("Notebook 1 started")

print("Notebook 1 completed successfully")
```

### Expected Output

```text
Notebook 1 started
Notebook 1 completed successfully
```

---

## 3. Notebook 2

Create another Databricks notebook with the name:

```text
notebook_2
```

### Code

[notebook_2.py](notebook_2.py)

```python
print("Notebook 2 started")

print("Notebook 2 completed successfully")
```

### Expected Output

```text
Notebook 2 started
Notebook 2 completed successfully
```

---

## 4. Create Databricks Job

Create a new **Job** in Databricks.

### Task 1

```text
Task name: notebook_1
Type: Notebook
Notebook: notebook_1
```

### Task 2

```text
Task name: notebook_2
Type: Notebook
Notebook: notebook_2
```

---

## 5. Configure Dependency

For **Task 2 (`notebook_2`)**, configure:

```text
Depends on: notebook_1
```

This means:

> `notebook_2` will execute only after `notebook_1` completes successfully.

In the Databricks UI this is the **Depends on** dropdown on the Task 2 configuration panel. Under the hood it is written into the job definition, which is what [job_definition.json](job_definition.json) shows:

```json
{
  "task_key": "notebook_2",
  "depends_on": [
    {
      "task_key": "notebook_1"
    }
  ],
  "notebook_task": {
    "notebook_path": "/Workspace/Users/<your-email>/notebook_2"
  },
  "run_if": "ALL_SUCCESS"
}
```

Two fields do the work here:

| Field | Meaning |
| ----- | ------- |
| `depends_on` | Lists the tasks that must finish before this one starts. Here, `notebook_1` |
| `run_if` | The condition for running. `ALL_SUCCESS` means every task in `depends_on` must succeed |

`run_if` defaults to `ALL_SUCCESS`, so it would behave the same way even if you left it out — writing it explicitly makes the intent readable.

---

## 6. Job Dependency Flow

```mermaid
flowchart TD
    A["Notebook 1"] -->|SUCCESS| B["Notebook 2"]
```

### Complete Flow

```text
Notebook 1
    ↓
Notebook 1 started
    ↓
Notebook 1 completed successfully
    ↓
Notebook 2 starts
    ↓
Notebook 2 started
    ↓
Notebook 2 completed successfully
```

---

## 7. Expected Job Execution

When you run the Job:

### Step 1

```text
Notebook 1 starts
```

Output:

```text
Notebook 1 started
Notebook 1 completed successfully
```

### Step 2

After Notebook 1 succeeds:

```text
Notebook 2 starts
```

Output:

```text
Notebook 2 started
Notebook 2 completed successfully
```

In the **Runs** view you will see the two tasks as two boxes joined by an arrow. Notebook 1 turns green first, then Notebook 2 starts — never at the same time.

---

## 8. Key Point

The dependency is:

```text
Notebook 1 → Notebook 2
```

**Notebook 2 does not start until Notebook 1 finishes successfully.**

---

## 9. What If Notebook 1 Fails?

This is the part worth testing, since it is the whole reason a dependency exists.

Add a line to Notebook 1 that raises an error:

```python
raise Exception("Notebook 1 failed on purpose")
```

Then run the job again:

```text
Notebook 1  →  FAILED
Notebook 2  →  UPSTREAM_FAILED
```

Notebook 2 never ran. Its result state is **`UPSTREAM_FAILED`** — *"the run was skipped because of an upstream failure"* — because `run_if: ALL_SUCCESS` was never satisfied.

It is **not** reported as Failed. That distinction matters when you read a failed job run, because these two mean very different things:

| Result state | Meaning |
| ------------ | ------- |
| `FAILED` | The task **ran** and threw an error. The problem is inside this task |
| `UPSTREAM_FAILED` | The task **never ran**. Something it depends on failed — look upstream |
| `UPSTREAM_CANCELED` | The task never ran, because an upstream task was canceled |
| `EXCLUDED` | The task never ran, and a failure-handling condition was not met. Treated as successful |
| `DISABLED` | The task never ran, because it was disabled in the job config |

So if you see a task in a failed run, the first question is whether it says `FAILED` or `UPSTREAM_FAILED`. Only the first one is worth debugging in that task.

### Running a task even when an upstream task fails

A common need: run a cleanup or alerting notebook **whatever** happens upstream. For that, change the condition:

```json
"run_if": "ALL_DONE"
```

`ALL_DONE` runs the task once all dependencies have finished, **regardless of whether they succeeded or failed**. That is the correct choice for a failure-notification task.

> ⚠️ Do **not** use `AT_LEAST_ONE_SUCCESS` for this. It means "at least one dependency succeeded" — with a single dependency that failed, that condition is still not satisfied, so the task would be skipped again. It looks like the right option and is not.

The available `run_if` values:

| Value | The task runs when… |
| ----- | ------------------- |
| `ALL_SUCCESS` | every dependency succeeded *(default)* |
| `AT_LEAST_ONE_SUCCESS` | at least one dependency succeeded |
| `ALL_DONE` | all dependencies finished, success or failure |
| `AT_LEAST_ONE_FAILED` | at least one dependency failed |
| `ALL_FAILED` | every dependency failed |

Remove the `raise` line before moving on.

---

## 10. Why Chain Notebooks at All?

The same pattern is used for real pipelines where each step must finish before the next starts:

```text
Notebook 1  →  ingest raw files
Notebook 2  →  clean and validate
Notebook 3  →  aggregate and write gold tables
```

Without dependencies, Databricks would run all three at once and the clean step would read files the ingest step had not written yet.

Each task's result also becomes visible separately in the Runs view, so you can see exactly which step failed instead of debugging one large notebook.

---

### 🎯 Interview Explanation

> **"I created a Databricks Job with two notebook tasks. Notebook 2 has a dependency on Notebook 1, so Notebook 2 executes only after Notebook 1 completes successfully. This allows us to create sequential notebook workflows in Databricks Jobs."**
