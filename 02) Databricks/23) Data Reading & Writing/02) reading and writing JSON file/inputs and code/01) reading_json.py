from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Read Practice").getOrCreate()

df = spark.read.json("/Volumes/workspace/default/json_volume/input/employees.json")

df.display()
df.printSchema()
