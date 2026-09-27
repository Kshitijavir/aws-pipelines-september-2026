# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/02) employees_single_line_array.json
# OUTPUT   : /Volumes/workspace/default/json_volume/output/employees_single_line_array.json
# PURPOSE  : WRITE a top-level JSON ARRAY on ONE line - the shape Spark
#            cannot produce on its own. Includes the workaround.
# ============================================================

import json
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Single Line Array Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .json("/Volumes/workspace/default/json_volume/input/employees_single_line_array.json")

df.show()

# ------------------------------------------------------------
# ❌ WHAT SPARK DOES BY DEFAULT - one object PER LINE, never an array
# ------------------------------------------------------------
df.write \
    .mode("overwrite") \
    .json("/Volumes/workspace/default/json_volume/output/employees_jsonlines_mode_overwrite/")
# -> {"employee_id":101,...}
#    {"employee_id":102,...}      <- NOT what we want here

# ------------------------------------------------------------
# ✅ THE WORKAROUND - build the array string yourself, then write text
# ------------------------------------------------------------
# 1) bring the rows back to the driver and turn them into a Python list
rows = [row.asDict() for row in df.collect()]

# 2) json.dumps gives us: [{"employee_id": 101, ...}, {...}] on ONE line
payload = json.dumps(rows)

# 3) wrap that single string in a 1-row DataFrame and write it as TEXT
single = spark.createDataFrame([(payload,)], ["value"])

single.coalesce(1).write \
    .mode("overwrite") \
    .text("/Volumes/workspace/default/json_volume/output/employees_single_line_array_mode_overwrite/")
# ⚠️ NOTE the path is a FOLDER ending in "/" - NOT "....json".
#    Writing ".../employees_single_line_array.json" would create a DIRECTORY
#    called that, with part-00000-....txt inside it - not a JSON file.

# ============================================================
# NOTES
# ============================================================
# 1. ⚠️⚠️ THE BIG WARNING: .collect() PULLS EVERY ROW TO THE DRIVER.
#
#    df.collect()
#      -> all data leaves the executors and lands in the driver's memory
#      -> on a big dataset this OOMs the driver and KILLS the job
#
#    ✅ ONLY use this pattern for SMALL results (a config payload, a summary,
#       a few hundred rows). For real data, keep JSON Lines.
#
#    This is the single most important thing to understand about this file:
#    the array-on-one-line shape is convenient for some APIs, but it is
#    FUNDAMENTALLY not a distributed format.
#
# 2. 🎯 WHY THIS SHAPE AT ALL?
#    Some HTTP APIs and some older tools accept ONLY a top-level JSON array:
#           [ {...}, {...}, {...} ]
#    and cannot parse JSON Lines. So you occasionally have to produce it.
#
# 3. ⚠️ NOTHING IS PURE-MAPREDUCE HERE. To make ONE line you must have the
#    whole dataset in ONE place. That is why:
#           .coalesce(1)   -> force a single output file
#    Both steps fight against distribution - they are a deliberate
#    trade-off for a consumer that demands this shape.
#
# 4. 🔁 NOTICE THE SYMMETRY WITH READING.
#    On the READING side we saw that an array on one line works with no
#    option needed. Here we see WHY such files are usually small: producing
#    them requires collapsing everything to one place, so people only do it
#    for small payloads.
#
# 5. WRITE MODES - covered in full in ../01) writing_json.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 6. 💡 THE SAFER ALTERNATIVE for a single JSON document: write JSON Lines
#    normally, then let the CONSUMER join the lines. Or store it as ONE JSON
#    object per file so each file stands alone. Only build the array when a
#    specific system truly demands it.
