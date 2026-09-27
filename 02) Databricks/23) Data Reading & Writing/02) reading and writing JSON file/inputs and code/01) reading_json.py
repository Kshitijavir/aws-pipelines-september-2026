# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 01) employees.json
#            (LINE-DELIMITED json - one object per line)
# PURPOSE  : The base case - read JSON Lines from a Databricks volume with no options.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .json("/Volumes/workspace/default/json_volume/input/employees.json")

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. NO .option("header", "true")
#       -> JSON keys ARE the column names. Nothing to declare.
#
# 2. NO .option("inferSchema", "true")
#       -> JSON is already typed ("Rahul" = string, 60000 = number).
#          JSON numbers come back as long / double (not integer).
#
# 3. This script reads the DEFAULT shape - one complete JSON object
#       per line. For the other two shapes see the sibling scripts:
#
#           reading_json_nested.py              whole file = ONE document
#           reading_json_single_line_array.py   array on ONE single line
#
# 4. You can also point at a FOLDER instead of a file:
#       .json("/Volumes/workspace/default/json_volume/input/")
#    Spark will read every .json file inside it.
#
# 5. JSON Lines is the shape you WANT for big data - Spark can split
#       the file across executors at line boundaries. multiLine cannot.
