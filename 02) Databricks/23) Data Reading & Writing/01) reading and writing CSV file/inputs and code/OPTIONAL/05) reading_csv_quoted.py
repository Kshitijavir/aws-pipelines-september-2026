# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 05) employees_quoted.csv   (comma + QUOTED fields)
# PURPOSE  : Handle a comma CSV that contains commas INSIDE values,
#            wrapped in double quotes.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Quoted Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", ",") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_quoted.csv")

df.printSchema()

df.show(truncate=False)

# ============================================================
# NOTES
# ============================================================
# 1. The problem this solves:
#
#       101,Rahul,IT,"Hyderabad, Telangana",60000
#                      ^------------------^
#                      a COMMA inside the value
#
#       Without quote handling Spark would split this into 6 parts
#       and your columns would shift by one.
#
# 2. .option("quote", "\"")   -> the character used to WRAP a value.
#       Default is already a double quote, so this is often implicit -
#       writing it makes the pipeline explicit and easier to read.
#
# 3. .option("escape", "\"")  -> the character used to ESCAPE a quote
#       INSIDE a quoted value, e.g.  "He said ""hello"""
#
# 4. Always use show(truncate=False) with quoted fields - the values
#       are long and the default show() will cut them with "...".
#
# 5. Read into a single column? Your quote/escape pair is wrong, or the
#       file uses single quotes. In that case:
#           .option("quote", "'")
