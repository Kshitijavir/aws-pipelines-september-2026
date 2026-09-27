# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 04) employees_semicolon.csv   (SEMICOLON-delimited)
# PURPOSE  : Read a semicolon-separated file (very common in
#            European / Excel exports, where "," is the decimal mark).
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Semicolon Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", ";") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_semicolon.csv")

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. The reason ";" is popular: in many countries 60000.50 uses a
#       DOT as decimal separator and 1.234,56 style numbers exist,
#       so "," cannot be used as a field separator. ";" solves that.
#
# 2. Only the sep changes. header + inferSchema behave exactly
#       the same as with a normal comma CSV.
#
# 3. If you do not know the delimiter of a file:
#           read the first 2 lines and count the characters.
#       Never guess - a wrong sep silently produces one "_c0" column.
