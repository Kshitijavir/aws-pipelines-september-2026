from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("PARQUET Read Practice").getOrCreate()

df = spark.read.parquet("/Volumes/workspace/default/parquet_volume/input/table.parquet")

df.show()
df.printSchema()
