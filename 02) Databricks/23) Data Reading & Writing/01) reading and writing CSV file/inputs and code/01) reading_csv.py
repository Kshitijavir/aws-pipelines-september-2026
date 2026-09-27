# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 01) employees.csv   (COMMA-delimited, with header)
# PURPOSE  : The base case - read a normal comma CSV from a Databricks volume.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees.csv")

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. .option("header", "true")
#       -> the first row holds the column names, not data.
#
# 2. .option("inferSchema", "true")
#       -> Spark guesses the data types (integer, string, ...).
#          It costs an extra pass over the file and can surprise you
#          when the source data changes - in production an explicit
#          schema is preferred (next topic).
#
# 3. .csv(...) uses a COMMA by default. For other delimiters see the
#       sibling scripts in this folder:
#
#           reading_csv_pipe.py        sep = "|"
#           reading_csv_tab.py         sep = "\t"
#           reading_csv_semicolon.py   sep = ";"
#           reading_csv_quoted.py      commas INSIDE quoted values
#           reading_csv_no_header.py   no header row at all

