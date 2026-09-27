# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 06) employees_fixed_width.txt
#            (NO delimiter - every field sits at a fixed position)
# PURPOSE  : Read a fixed-width text file (legacy / mainframe style)
#            by cutting the line at character positions.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Fixed Width Read Practice").getOrCreate()

from pyspark.sql.functions import col, trim

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

raw = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees_fixed_width.txt")

# value = "101 Rahul   IT       60000"
#          ^^^ ^^^^^^^ ^^^^^^^^ ^^^^^
#          1-3  5-11    13-20    22-26
df = raw.select(
    trim(col("value").substr(1, 3)).cast("integer").alias("employee_id"),
    trim(col("value").substr(5, 7)).alias("name"),
    trim(col("value").substr(13, 8)).alias("department"),
    trim(col("value").substr(22, 5)).cast("integer").alias("salary")
)

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. substr(start, length) is 1-BASED in Spark:
#
#           substr(1, 3)   ->  characters 1, 2, 3
#
#    NOT 0-based like Python slicing. Off-by-one here silently gives
#    you the wrong letters - always verify with a real row.
#
# 2. .text() reads the raw line -> "value". Then substr slices it.
#       For fixed-width there is no delimiter to give .csv(), so
#       .text() + substr is the standard approach.
#
# 3. ALWAYS trim() after substr, because a short value leaves padding
#       spaces behind:  "IT      " -> trim -> "IT"
#
# 4. Then CAST, exactly like every other .text() parse, because the
#       sliced values are still strings.
#
# 5. Where do fixed-width files come from? Mainframes (COBOL copybooks),
#       old banking / insurance / telecom dumps, government data.
#       The position map (1-3, 5-11, ...) is your "copybook" - keep it
#       in a comment, as done above. That map IS the schema.
#
# 6. Alternatives for messy positions:
#           substring(col("value"), 1, 3)   same thing, function form
#           pyspark.sql.functions.split(col("value"), "\\s+")
#               -> easier when fields are separated by 1+ spaces
#
# 7. If the layout ever shifts by one column, everything moves - which
#       is why fixed-width is the most brittle text format there is.
