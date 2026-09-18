# Databricks notebook source
# All three notebooks of the Databricks job in one file.
#
# In Databricks these are three separate notebooks (databricks_notebook_1.py,
# _2.py, _3.py) wired as three tasks of one job, so the job only reports
# SUCCESS once the last notebook finishes — which is what the Lambda polls for.
#
# Each "# COMMAND ----------" block below is one notebook cell, so you can paste
# this whole file into a single notebook and run it cell by cell, or split the
# cells back out into the three notebooks.

# COMMAND ----------

# MAGIC %md
# MAGIC # Notebook 1 of 3

# COMMAND ----------

import time
from datetime import datetime

print("========================================")
print("Notebook 1 Started")
print("Start Time:", datetime.now())
print("========================================")

for i in range(1, 10):
    print(f"Notebook 1 - Processing step {i}/9")
    time.sleep(10)

print("========================================")
print("Notebook 1 Completed Successfully")
print("End Time:", datetime.now())
print("========================================")

# COMMAND ----------

# MAGIC %md
# MAGIC # Notebook 2 of 3

# COMMAND ----------

import time
from datetime import datetime

print("========================================")
print("Notebook 2 Started")
print("Start Time:", datetime.now())
print("========================================")

for i in range(1, 10):
    print(f"Notebook 2 - Processing step {i}/9")
    time.sleep(10)

print("========================================")
print("Notebook 2 Completed Successfully")
print("End Time:", datetime.now())
print("========================================")

# COMMAND ----------

# MAGIC %md
# MAGIC # Notebook 3 of 3

# COMMAND ----------

import time
from datetime import datetime

print("========================================")
print("Notebook 3 Started")
print("Start Time:", datetime.now())
print("========================================")

for i in range(1, 10):
    print(f"Notebook 3 - Processing step {i}/9")
    time.sleep(10)

print("========================================")
print("Notebook 3 Completed Successfully")
print("End Time:", datetime.now())
print("========================================")
