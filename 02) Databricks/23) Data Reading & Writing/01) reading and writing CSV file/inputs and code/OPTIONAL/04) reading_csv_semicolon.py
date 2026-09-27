from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Semicolon Read Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/csv_volume/input/employees_semicolon.csv",
    sep=";",
    header=True,
    inferSchema=True
)

df.show()
df.printSchema()
