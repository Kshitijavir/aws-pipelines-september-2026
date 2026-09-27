# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/02) employees_pipe.csv   (pipe-delimited)
# OUTPUT   : /Volumes/workspace/default/csv_volume/output/employees_pipe/
# PURPOSE  : WRITE a PIPE-delimited CSV - the same .option("sep", "|")
#            that reading used, but on the write side.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Pipe Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", "|") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_pipe.csv")

df.show()

# ---------- WRITE AS PIPE-DELIMITED ----------
df.write \
    .mode("overwrite") \
    .option("sep", "|") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_pipe_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. 🎯 READING AND WRITING ARE SYMMETRIC.
#
#       read:   .option("sep", "|").csv(in_path)
#       write:  .option("sep", "|").csv(out_path)
#
#    Same option name, same meaning, same position. What you learn on one
#    side transfers straight to the other.
#
# 2. ⚠️ THE #1 REAL-WORLD USE OF THIS: CHANGING A FILE'S DELIMITER.
#    A vendor gives you a comma CSV but the next system wants pipes:
#
#       read comma  →  write pipe
#
#    That is a genuinely common Databricks job, and it is this script.
#
# 3. WRITE MODES - covered in full in ../01) writing_csv.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 4. 📂 The output is a FOLDER of part files, not one file:
#           employees_pipe/
#           ├── part-00000-....csv
#           └── _SUCCESS
#
# 5. Delimiters Spark can write: single characters only - "|", ";", "\t".
#    For a MULTI-character separator you must build the line yourself
#    (concat_ws) and write with .text() instead.
