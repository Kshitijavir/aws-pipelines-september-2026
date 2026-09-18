# Databricks notebook source
# Notebook 2 of 3 in the Databricks job that Step Functions triggers.
# Plain-python stand-in for the real workload: it just logs progress for ~90 seconds.

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
