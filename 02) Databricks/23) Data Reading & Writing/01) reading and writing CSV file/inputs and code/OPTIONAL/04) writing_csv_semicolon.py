# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/04) employees_semicolon.csv   (semicolon-delimited)
# OUTPUT   : /Volumes/workspace/default/csv_volume/output/employees_semicolon/
# PURPOSE  : WRITE a SEMICOLON-delimited file (European / Excel style).
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Semicolon Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", ";") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_semicolon.csv")

df.show()

# ---------- WRITE AS SEMICOLON-DELIMITED ----------
df.write \
    .mode("overwrite") \
    .option("sep", ";") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_semicolon_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. 🎯 WHY SEMICOLONS EXIST: in many countries a number is written
#    60000,50 - with a COMMA as the decimal separator. That makes a comma
#    useless as a field separator, so ";" was adopted instead.
#
#    So this write is mostly about handing data to a European / Excel
#    user who cannot open a comma file correctly.
#
# 2. ⚠️ THE DECIMAL-SEPARATOR TRAP. Spark always writes numbers in
#    ENGLISH format (60000.50 with a DOT). If the receiving system expects
#    "60000,50", the separator alone is not enough - you must format the
#    number as text, e.g. with regexp_replace:
#
#           from pyspark.sql.functions import regexp_replace, col
#           df = df.withColumn("salary_text",
#                              regexp_replace(col("salary").cast("string"), "\\.", ","))
#
#    Then write that text column.
#
# 3. WRITE MODES - covered in full in ../01) writing_csv.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 4. 📂 Output is a FOLDER of part files - not one file.
