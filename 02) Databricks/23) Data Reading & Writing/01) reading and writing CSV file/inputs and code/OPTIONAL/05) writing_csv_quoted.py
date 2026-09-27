from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Quoted Write Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/csv_volume/input/employees_quoted.csv",
    sep=",",
    quote='"',
    escape='"',
    header=True,
    inferSchema=True
)

df.display()
df.printSchema()

df.write.mode("overwrite").parquet(
    "/Volumes/workspace/default/csv_volume/output/employees_quoted_parquet/"
)
