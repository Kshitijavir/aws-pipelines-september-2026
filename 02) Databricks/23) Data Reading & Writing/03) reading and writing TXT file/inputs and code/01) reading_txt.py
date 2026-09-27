from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Read Practice").getOrCreate()

df = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees.txt")

df.show(truncate=False)
df.printSchema()
