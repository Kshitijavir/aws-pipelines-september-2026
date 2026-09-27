# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/05) employees_quoted.csv   (commas inside values)
# OUTPUT   : /Volumes/workspace/default/csv_volume/output/employees_quoted/
# PURPOSE  : WRITE a CSV where values CONTAIN the delimiter, so they
#            must be wrapped in quotes.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Quoted Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", ",") \
    .option("quote", "\"") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_quoted.csv")

df.show(truncate=False)

# ---------- WRITE WITH QUOTING ----------
df.write \
    .mode("overwrite") \
    .option("sep", ",") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_quoted_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. 🎯 THE PROBLEM THIS SOLVES
#
#       101,Rahul,IT,"Hyderabad, Telangana",60000
#                      ^------------------^
#                      the VALUE contains a comma
#
#    If it is not quoted, the reader sees 6 fields instead of 5 and every
#    column after it shifts - silent, nasty corruption.
#
#    Quoting says: "everything between these characters is ONE value".
#
# 2. ✅ GOOD NEWS: SPARK QUOTES AUTOMATICALLY WHEN IT NEEDS TO.
#    When a value contains the delimiter (or a newline, or the quote
#    character), Spark wraps and escapes it for you. You do not have to
#    build the string by hand.
#
#    The options just let you CONTROL the characters:
#        .option("quote", "\"")     the wrapping character (default ")
#        .option("escape", "\"")    how to escape a quote INSIDE a value
#
# 3. 🎤 INTERVIEW POINT: "How do you write a CSV when the data contains
#    commas?" -> you do not escape it yourself; CSV quoting handles it, and
#    Spark applies quoting automatically. The thing you must get right is
#    that the CONSUMER expects the same quote/escape characters.
#
# 4. WRITE MODES - covered in full in ../01) writing_csv.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 5. ⚠️ Quote-related failures are almost always an EXCEL problem:
#    Excel may re-quote, strip quotes, or change the delimiter on save.
#    If a downstream team says "your file is broken", check what they did
#    to it, not just what Spark wrote.
#
# 6. 📂 Output is a FOLDER of part files.
