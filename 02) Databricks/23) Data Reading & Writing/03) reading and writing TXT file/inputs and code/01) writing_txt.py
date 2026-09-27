from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Write Practice").getOrCreate()

df = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees.txt")

display(df)
df.printSchema()

df.write.mode("overwrite").parquet(
    "/Volumes/workspace/default/txt_volume/output/employees_parquet/"
)
