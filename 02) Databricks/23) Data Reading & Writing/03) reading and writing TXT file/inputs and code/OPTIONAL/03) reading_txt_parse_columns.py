from pyspark.sql import SparkSession
from pyspark.sql.functions import col, split, trim

# Create Spark Session
spark = SparkSession.builder.appName("TXT Parse Columns Read Practice").getOrCreate()

raw = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees_pipe.txt")

parts = split(col("value"), "\\|")

df = raw.select(
    trim(parts[0]).cast("integer").alias("employee_id"),
    trim(parts[1]).alias("name"),
    trim(parts[2]).alias("department"),
    trim(parts[3]).cast("integer").alias("salary")
)

df.display()
df.printSchema()
