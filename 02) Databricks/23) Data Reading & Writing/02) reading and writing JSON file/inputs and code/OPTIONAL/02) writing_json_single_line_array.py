from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Single Line Array Write Practice").getOrCreate()

df = spark.read.json(
    "/Volumes/workspace/default/json_volume/input/employees_single_line_array.json"
)

display(df)
df.printSchema()

df.write.mode("overwrite").parquet(
    "/Volumes/workspace/default/json_volume/output/employees_single_line_array_parquet/"
)
