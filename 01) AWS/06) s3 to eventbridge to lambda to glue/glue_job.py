import sys

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext


# Get arguments passed by Lambda
# JOB_NAME is filled in by Glue itself with the job's own name,
# so this script never hardcodes the job name either.
args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "bucket_name", "object_key"]
)

bucket_name = args["bucket_name"]
object_key = args["object_key"]


# Create Spark Context
sc = SparkContext.getOrCreate()

glueContext = GlueContext(sc)

spark = glueContext.spark_session


# Initialize Glue Job
job = Job(glueContext)

job.init(args["JOB_NAME"], args)


# Build S3 path dynamically
s3_path = f"s3://{bucket_name}/{object_key}"


print("===== GLUE JOB STARTED =====")

print(f"Bucket Name : {bucket_name}")
print(f"Object Key  : {object_key}")
print(f"S3 Path     : {s3_path}")


print("===== READING FILE =====")


df = spark.read.option(
    "header",
    "true"
).csv(s3_path)


print("File read successfully")

print(f"File Name / Object Key: {object_key}")


df.show()


job.commit()
