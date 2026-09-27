# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 03) employees_tab.csv   (TAB-delimited)
# PURPOSE  : Read a tab-separated file (TSV stored with a .csv name).
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Tab Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", "\t") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_tab.csv")

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. Tab is written as "\t" in Python.
#       Python turns it into ONE real tab character before Spark sees it.
#
# 2. "\t" is 2 characters in the source but 1 character at runtime -
#       that is what sep requires (a single character).
#
# 3. If a tab file was created on Windows you may also need:
#           .option("lineSep", "\r\n")
#
# 4. There is also a dedicated name for tab files:
#           .option("sep", "\t")   ==   spark.read.csv(...)
#       Spark has no separate ".tsv()" method - always ".csv()" + sep.
