# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 01) employees.txt   (raw log lines, no structure)
# PURPOSE  : The base case - read a text file line by line with .text()
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .text("/Volumes/workspace/default/txt_volume/input/employees.txt")

df.printSchema()

df.show(truncate=False)

# ============================================================
# NOTES
# ============================================================
# 1. .text() gives you ONE column called "value", type string,
#       with one row per line. There is NO schema discovery.
#       -> printSchema() always shows:  value: string
#
# 2. NO header, NO inferSchema, NO multiLine.
#       CSV  = delimited text  -> Spark needs the delimiter
#       JSON = self-describing -> keys + types are in the file
#       TXT  = just characters -> Spark knows nothing about the meaning
#
# 3. ALWAYS use show(truncate=False) for TXT, otherwise long lines
#       get cut off with "...".
#
# 4. Every other TXT case has its own script in this folder:
#
#       reading_txt_wholetext.py       whole file = ONE row
#       reading_txt_parse_columns.py   split / regex a raw .text() DataFrame
#       reading_txt_pipe.py            pipe-delimited .txt (sep = "|")
#       reading_txt_tab.py             tab-delimited .txt  (sep = "\t")
#       reading_txt_fixed_width.py     fixed-width .txt (substr)
#
# 5. Other options: lineSep (e.g. "\r\n" for Windows files),
#       pathGlobFilter, recursiveFileLookup.
#
# 6. You can point at a FOLDER instead of a file:
#           .text("/Volumes/workspace/default/txt_volume/input/")
#
# 7. The typed built-in reader gives the same result:
#           spark.read.format("text")  ->  the field name is still "value"
