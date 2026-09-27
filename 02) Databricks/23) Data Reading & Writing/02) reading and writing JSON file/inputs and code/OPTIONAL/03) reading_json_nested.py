# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 03) employees_nested.json
#            (ONE json document - pretty-printed array, nested)
# PURPOSE  : Read a pretty-printed JSON document with multiLine and
#            reach into its nested struct / array fields.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Nested Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("multiLine", "true") \
    .json("/Volumes/workspace/default/json_volume/input/employees_nested.json")

df.printSchema()

df.show(truncate=False)

# Read into nested fields using DOT NOTATION
df.select("name", "address.city", "skills").show(truncate=False)

# ============================================================
# NOTES
# ============================================================
# 1. WHY multiLine IS NEEDED HERE
#
#       Line-delimited (default) :  {"a":1}
#                                   {"a":2}
#
#       One document             :  [
#                                     { "a": 1 },
#                                     { "a": 2 }
#                                   ]
#
#    In the second case the JSON is spread over MANY lines, so Spark
#    cannot read it line by line. multiLine=true tells Spark:
#           "the whole file is ONE JSON value - parse it as a whole".
#
#    Without it you get nulls or an empty DataFrame - no crash, just
#    silent wrongness. That is why it is a classic debugging trap.
#
# 2. NESTED FIELDS BECOME STRUCTS AND ARRAYS
#
#       skills  -> array   (element: string)
#       address -> struct  (city: string, country: string)
#
#    Access them with dot notation:
#           df.select("address.city")
#
# 3. show(truncate=False) is important here - nested values are long
#       and the default show() cuts them off with "...".
#
# 4. multiLine CANNOT be combined with wholeFile and is slower/less
#       parallel than line-delimited JSON, because a file can no longer
#       be split across executors at line boundaries. Prefer JSON Lines
#       for big data whenever you control the producer.
#
# 5. Other useful options:
#           .option("mode", "PERMISSIVE")            default
#           .option("mode", "FAILFAST")              fail on bad records
#           .option("samplingRatio", "0.1")          infer from 10% only
#           .option("allowComments", "true")
#           .option("allowSingleQuotes", "true")
#           .option("allowUnquotedFieldNames", "true")
