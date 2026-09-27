from pyspark.sql import SparkSession
from pyspark.sql.functions import col, trim

# Create Spark Session
spark = SparkSession.builder.appName("TXT Fixed Width Read Practice").getOrCreate()

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

display(df)
df.printSchema()
