# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 02) employees_single_line_array.json
#            (a json ARRAY that sits on ONE single line)
# PURPOSE  : Read a top-level JSON array WITHOUT multiLine - the
#            shape that confuses most people.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Single Line Array Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .json("/Volumes/workspace/default/json_volume/input/employees_single_line_array.json")

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. THIS IS THE CONFUSING ONE. Compare the three shapes:
#
#    SHAPE 1 - objects, one per line            -> works (default)
#           {"employee_id": 101, ...}
#           {"employee_id": 102, ...}
#
#    SHAPE 2 - ARRAY on ONE line                -> works (default)
#           [{"employee_id": 101, ...}, {"employee_id": 102, ...}]
#
#    SHAPE 3 - ARRAY spread over MANY lines     -> FAILS (needs multiLine)
#           [
#             {"employee_id": 101, ...},
#             {"employee_id": 102, ...}
#           ]
#
# 2. So the rule is NOT "array needs multiLine". The rule is:
#
#           Does ONE COMPLETE JSON VALUE fit on ONE LINE?
#                 YES  ->  no option needed
#                 NO   ->  .option("multiLine", "true")
#
# 3. In SHAPE 2 Spark reads the single line, sees an array, and
#       produces ONE ROW PER ELEMENT - exactly the 4 rows you want.
#
# 4. Production reality check: many REST APIs return SHAPE 3
#       (pretty-printed arrays) when you save them straight to a file.
#       That is the #1 reason people add multiLine in real pipelines.
#
# 5. If you are unsure which shape a file is, open it and look at
#       line 1 and line 2:
#           line 1 starts with "[" and is short  -> SHAPE 2
#           line 1 is just "[" on its own        -> SHAPE 3
#
# 6. Best practice for large files: always write JSON Lines (SHAPE 1)
#       so Spark can split the file across executors.
