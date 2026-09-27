from pyspark.sql import SparkSession
from pyspark.sql.functions import col, regexp_extract, to_date

# Create Spark Session
spark = SparkSession.builder.appName("TXT Parse Columns Write Practice").getOrCreate()

raw = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees.txt")

df = raw.select(
    to_date(regexp_extract("value", r"^(\d{4}-\d{2}-\d{2})", 1)).alias("log_date"),
    regexp_extract("value", r"\b(INFO|WARN|ERROR)\b", 1).alias("level"),
    regexp_extract("value", r"Employee (\w+)", 1).alias("employee")
)

df.display()
df.printSchema()

df.write.mode("overwrite").parquet(
    "/Volumes/workspace/default/txt_volume/output/employees_parsed_parquet/"
)
