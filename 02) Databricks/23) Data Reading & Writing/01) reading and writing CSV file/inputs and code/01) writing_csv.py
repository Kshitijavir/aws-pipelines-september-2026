from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Write Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/csv_volume/input/employees.csv",
    header=True,
    inferSchema=True
)

display(df)
df.printSchema()

df.write.mode("overwrite").parquet(
    "/Volumes/workspace/default/csv_volume/output/employees_parquet/"
)
