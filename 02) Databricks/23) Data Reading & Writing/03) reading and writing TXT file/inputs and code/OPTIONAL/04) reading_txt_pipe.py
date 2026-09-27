# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 04) employees_pipe.txt   (PIPE-delimited .txt)
# PURPOSE  : A .txt file WITH a delimiter is really a CSV.
#            So we read it with .csv() + .option("sep", "|").
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Pipe Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", "|") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/txt_volume/input/employees_pipe.txt")

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. ⭐ THE KEY IDEA: Spark reads by CONTENT, not by file EXTENSION.
#
#       employees_pipe.txt   ->  .csv(sep="|")
#       employees_pipe.csv   ->  .csv(sep="|")     (identical result)
#
#    The ".txt" name changes nothing. If the content is delimited,
#    .csv() is the right reader.
#
# 2. WHY NOT .text()?  Because .text() would hand you ONE raw string
#       column called "value" and you would have to split it yourself.
#       `.csv()` gives you 4 real, TYPED columns for free.
#
#       Use .text()  -> when the file is unstructured (logs, free text)
#       Use .csv()   -> when the file only LOOKS unstructured
#
# 3. Alternate route with the SAME result, done by hand:
#           raw  = spark.read.text(path)
#           parts = split(col("value"), "\\|")
#       See reading_txt_parse_columns.py for that version.
#
# 4. header/inferSchema work here EXACTLY like on a normal CSV, because
#       it IS a normal CSV as far as Spark is concerned.
