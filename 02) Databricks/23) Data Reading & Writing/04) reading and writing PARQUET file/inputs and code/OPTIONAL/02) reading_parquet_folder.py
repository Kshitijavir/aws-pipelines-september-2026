from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("PARQUET Folder Read Practice").getOrCreate()

# reading a FOLDER of part files written by one job
df = spark.read.parquet("/Volumes/workspace/default/parquet_volume/input/employees_parquet/")

display(df)
df.printSchema()
