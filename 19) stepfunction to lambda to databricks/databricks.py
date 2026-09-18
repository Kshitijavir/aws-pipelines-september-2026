# Databricks notebooks for the job that Step Functions triggers.
#
# The job has 3 notebooks, wired as 3 chained tasks, so the job only reports
# SUCCESS once the last notebook finishes -- which is what the Lambda polls for.
# All three are kept in this one file, split up by comments.

# ========================================
# 1st notebook code
# ========================================
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


# ========================================
# 2nd notebook code
# ========================================
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


# ========================================
# 3rd notebook code
# ========================================
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
