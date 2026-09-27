from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Nested Write Practice").getOrCreate()

df = spark.read.json(
    "/Volumes/workspace/default/json_volume/input/employees_nested.json",
    multiLine=True
)

df.show(truncate=False)
df.printSchema()

df.write.mode("overwrite").parquet(
    "/Volumes/workspace/default/json_volume/output/employees_nested_parquet/"
)
