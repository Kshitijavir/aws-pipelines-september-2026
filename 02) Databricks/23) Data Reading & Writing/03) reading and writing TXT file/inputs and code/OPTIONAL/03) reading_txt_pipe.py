from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Pipe Read Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/txt_volume/input/employees_pipe.txt",
    sep="|",
    header=True,
    inferSchema=True
)

df.display()
df.printSchema()
