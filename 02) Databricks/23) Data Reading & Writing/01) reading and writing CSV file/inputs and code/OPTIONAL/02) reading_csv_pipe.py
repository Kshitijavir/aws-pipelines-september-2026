from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Pipe Read Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/csv_volume/input/employees_pipe.csv",
    sep="|",
    header=True,
    inferSchema=True
)

display(df)
df.printSchema()
