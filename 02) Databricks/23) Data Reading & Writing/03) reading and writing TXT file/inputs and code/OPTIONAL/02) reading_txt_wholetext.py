from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Whole Text Read Practice").getOrCreate()

df = spark.read.text(
    "/Volumes/workspace/default/txt_volume/input/wholetext_employees.txt",
    wholetext=True
)

df.display()
df.printSchema()
