# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/03) employees_tab.csv   (tab-delimited)
# OUTPUT   : /Volumes/workspace/default/csv_volume/output/employees_tab/
# PURPOSE  : WRITE a TAB-delimited file (a TSV).
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Tab Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", "\t") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_tab.csv")

df.show()

# ---------- WRITE AS TAB-DELIMITED ----------
df.write \
    .mode("overwrite") \
    .option("sep", "\t") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_tab_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. "\t" in Python becomes ONE real tab character - which is what
#    .option("sep", ...) requires.
#
# 2. 🎯 USE CASE: writing a file for a system that expects TSV.
#    Databases, mainframe exports and some BI tools read tab files
#    natively, so "CSV in -> TSV out" is a very common Databricks job.
#
# 3. WRITE MODES - covered in full in ../01) writing_csv.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 4. ⚠️ WATCH OUT FOR YOUR SOURCE DATA. If a value ALREADY contains a tab,
#    the written file becomes ambiguous - the reader on the other end will
#    see extra columns. Either strip it first:
#
#           from pyspark.sql.functions import regexp_replace, col
#           df = df.withColumn("name", regexp_replace(col("name"), "\t", " "))
#
#    ...or use a safer delimiter and quote the values.
#
# 5. 📂 Output is a FOLDER of part files - not one .tsv file.
