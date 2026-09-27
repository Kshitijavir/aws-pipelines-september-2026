from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Tab Read Practice").getOrCreate()

df = spark.read.csv(
    "/Volumes/workspace/default/txt_volume/input/employees_tab.txt",
    sep="\t",
    header=True,
    inferSchema=True
)

display(df)
df.printSchema()
