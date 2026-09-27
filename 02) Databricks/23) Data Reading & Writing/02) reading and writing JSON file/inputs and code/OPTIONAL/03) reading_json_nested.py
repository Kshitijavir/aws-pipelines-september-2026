from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Nested Read Practice").getOrCreate()

df = spark.read.json(
    "/Volumes/workspace/default/json_volume/input/employees_nested.json",
    multiLine=True
)

display(df)
df.printSchema()
