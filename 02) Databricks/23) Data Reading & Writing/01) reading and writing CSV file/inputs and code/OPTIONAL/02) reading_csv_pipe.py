# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 02) employees_pipe.csv   (PIPE-delimited)
# PURPOSE  : Read a pipe-delimited CSV where the first row holds
#            the column names.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Pipe Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", "|") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_pipe.csv")

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. A pipe-delimited file is still CSV to Spark. The ONLY change is:
#           .option("sep", "|")
#       Default sep for .csv() is a comma (",").
#
# 2. sep can be a single character only. Multi-char separators are
#       NOT supported by .csv() - use multiDelimiter (Databricks)
#       or split() on a .text() DataFrame for that.
#
# 3. Common values:
#           ","   comma      (default)
#           "|"   pipe       -> often needs escaping in regex, so "\\|"
#           "\t"  tab
#           ";"   semicolon  -> common in European exports
#
# 4. Always check printSchema() afterwards. If sep is wrong you get
#       ONE column named "_c0" instead of four real columns -
#       that is the classic "my delimiter is wrong" symptom.
