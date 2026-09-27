from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV No Header Write Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/csv_volume/input/employees_no_header.csv",
    header=False,
    inferSchema=True
)

df = df.toDF("employee_id", "name", "department", "salary")

display(df)
df.printSchema()

df.write.mode("overwrite").parquet(
    "/Volumes/workspace/default/csv_volume/output/employees_no_header_parquet/"
)
