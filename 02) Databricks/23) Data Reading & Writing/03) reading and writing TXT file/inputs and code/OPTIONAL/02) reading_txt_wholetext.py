# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 01) employees.txt   (same file as 01) reading_txt.py)
# PURPOSE  : Read the ENTIRE file as ONE single row.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Whole Text Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("wholetext", "true") \
    .text("/Volumes/workspace/default/txt_volume/input/employees.txt")

df.printSchema()

df.show(truncate=False)   # 1 row = the whole file

df.count()                # -> 1

# ============================================================
# NOTES
# ============================================================
# 1. DEFAULT vs wholetext
#
#       wholetext = false (default)  ->  one ROW per LINE   (5 rows)
#       wholetext = true             ->  one ROW per FILE   (1 row)
#
# 2. The whole file arrives as a SINGLE string containing "\n" inside it.
#
# 3. ⚠️ ONLY use this for SMALL files. On a big file the whole content
#       lands in one row on one executor - straight to an OOM failure.
#
# 4. Good uses: small config files, XML / HTML snippets, a JSON payload
#       you want to parse as a whole in Python, certificate files.
#
# 5. RULES / LIMITS:
#           - cannot be combined with .option("lineSep", ...)
#           - the file cannot be split across executors any more
#           - with a FOLDER path you get one row PER FILE
#
# 6. Compare on the SAME input file:
#           reading_txt.py   -> 5 rows (one per line)
#           this script      -> 1 row  (the whole file)
