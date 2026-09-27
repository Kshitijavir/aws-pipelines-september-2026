from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Tab Read Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/csv_volume/input/employees_tab.csv",
    sep="\t",
    header=True,
    inferSchema=True
)

df.display()
df.printSchema()
