# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 01) employees.txt   (logs)  +  04) employees_pipe.txt   (delimited)
# PURPOSE  : Pull real columns out of a raw .text() DataFrame.
#            .text() only gives you "value" - this is how you fix that.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Parse Columns Read Practice").getOrCreate()

from pyspark.sql.functions import col, split, trim, regexp_extract, to_date

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

############################################################
# PART A - SPLIT a delimited line into columns
############################################################
raw = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees_pipe.txt")

# value = "101|Rahul|IT|60000"  ->  [101, Rahul, IT, 60000]
parts = split(col("value"), "\\|")

df = raw.select(
    trim(parts[0]).cast("integer").alias("employee_id"),
    trim(parts[1]).alias("name"),
    trim(parts[2]).alias("department"),
    trim(parts[3]).cast("integer").alias("salary")
)

df.printSchema()
df.show()

############################################################
# PART B - EXTRACT fields from a log line with regex
############################################################
logs = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees.txt")

log_df = logs.select(
    to_date(regexp_extract("value", r"^(\d{4}-\d{2}-\d{2})", 1)).alias("log_date"),
    regexp_extract("value", r"\b(INFO|WARN|ERROR)\b", 1).alias("level"),
    regexp_extract("value", r"Employee (\w+)", 1).alias("employee"),
    regexp_extract("value", r"from (\w+)", 1).alias("department")
)

log_df.printSchema()
log_df.show(truncate=False)

# ============================================================
# NOTES
# ============================================================
# 1. printSchema() AFTER a parse still shows mostly string!
#
#       split()  ->  array<string>
#       parts[0] ->  string   <-- still a string
#
#    So YOU must cast:
#           .cast("integer")
#
#    In CSV, inferSchema did this for you. In TXT it is always your job.
#
# 2. split() takes a REGEX, not a plain string. Pipe "|" means OR in
#       regex, so it MUST be escaped as "\\|". (Double backslash in the
#       Python source = one backslash in the regex.)
#
# 3. Other separators:
#           split(col("value"), ",")      comma
#           split(col("value"), "\\t")    tab
#           split(col("value"), "\\s+")   one or more spaces
#
# 4. regexp_extract(string, pattern, groupIndex)
#           - groupIndex 0 = the whole match, 1 = first ( ) group
#           - returns an EMPTY STRING when nothing matches (not null)
#       Use nullif(..., "") to turn empties into nulls if you need to.
#
# 5. Useful text functions: trim, ltrim, rtrim, lower, upper,
#       regexp_replace, translate, instr, length, substring, md5.
#
# 6. show(truncate=False) again - raw log lines are long.
