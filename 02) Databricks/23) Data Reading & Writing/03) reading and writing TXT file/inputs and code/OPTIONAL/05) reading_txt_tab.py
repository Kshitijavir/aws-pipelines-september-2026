# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 05) employees_tab.txt   (TAB-delimited .txt)
# PURPOSE  : Read a tab-separated text file.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Tab Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", "\t") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/txt_volume/input/employees_tab.txt")

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. Tab = "\t". Python converts it to ONE real tab character before
#       Spark sees it - which is what sep() requires.
#
# 2. Tab files are extremely common as exports from:
#           - databases (mysql / postgres COPY, sqlplus)
#           - mainframe / legacy systems
#           - ".tsv" and ".tab" files
#       They are still read with .csv() + sep - Spark has no .tsv().
#
# 3. Gotcha: many tools write tab files with a TRAILING tab on each
#       line. That produces an extra empty column at the end. Fix it:
#           df = df.drop("_c4")          # or select the columns you want
#       ...or strip it upstream before writing to the volume.
#
# 4. If the file was built on Windows, the line endings may be CRLF:
#           .option("lineSep", "\r\n")
#
# 5. For a truly unstructured text file use .text() instead - see
#       reading_txt.py.
