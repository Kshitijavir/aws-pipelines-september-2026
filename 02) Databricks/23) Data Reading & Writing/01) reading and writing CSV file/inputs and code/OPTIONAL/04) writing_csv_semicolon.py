from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Semicolon Write Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/csv_volume/input/employees_semicolon.csv",
    sep=";",
    header=True,
    inferSchema=True
)

df.show()
df.printSchema()

df.write.mode("overwrite").parquet(
    "/Volumes/workspace/default/csv_volume/output/employees_semicolon_parquet/"
)
