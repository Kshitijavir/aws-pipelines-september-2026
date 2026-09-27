# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 06) employees_no_header.csv   (NO header row)
# PURPOSE  : Read a CSV whose first row is DATA, not column names -
#            then give the columns proper names in code.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV No Header Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_no_header.csv")

# Without a header Spark names the columns _c0, _c1, _c2, _c3
df.printSchema()

# So we rename them ourselves
df = df.toDF("employee_id", "name", "department", "salary")

df.printSchema()

df.show()

# ============================================================
# NOTES
# ============================================================
# 1. With .option("header", "false") the first row becomes a DATA row.
#       Nothing is lost, but the columns get placeholder names:
#           _c0, _c1, _c2, _c3 ...
#
# 2. Two ways to give the columns real names:
#
#     (a) toDF() - renames positionally, in file order
#             df.toDF("employee_id", "name", "department", "salary")
#
#     (b) withColumnRenamed() - one column at a time
#             df.withColumnRenamed("_c0", "employee_id")
#
# 3. Because toDF() is POSITIONAL, it breaks silently if the source file
#       ever adds or reorders columns. That is why the really safe option
#       is an explicit schema (next topic) - it fails loudly instead.
#
# 4. header is "false" by default, so you can also just omit the option.
#       Writing it out makes the intent obvious to the next reader.
#
# 5. If a header file is read with header=false you will see your column
#       names sitting in the data as a normal row - that is the symptom.
