# Databricks notebook source
# Notebook 3 of 3 in the Databricks job that Step Functions triggers.
# Plain-python stand-in for the real workload: it just logs progress for ~90 seconds.

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
