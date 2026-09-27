from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Pipe Write Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/txt_volume/input/employees_pipe.txt",
    sep="|",
    header=True,
    inferSchema=True
)

display(df)
df.printSchema()

df.write.mode("overwrite").parquet(
    "/Volumes/workspace/default/txt_volume/output/employees_pipe_parquet/"
)
