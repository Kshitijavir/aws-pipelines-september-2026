import json
import os

import boto3

glue = boto3.client("glue")

# The Glue job name is NOT hardcoded in this file.
# It comes from the Lambda environment variable GLUE_JOB_NAME, so the same
# function can start any Glue job without a code change.
GLUE_JOB_NAME = os.environ.get("GLUE_JOB_NAME")

if not GLUE_JOB_NAME:
    raise RuntimeError(
        "GLUE_JOB_NAME environment variable is not set. "
        "Set it in Lambda -> Configuration -> Environment variables."
    )


def lambda_handler(event, context):

    print("===== EVENTBRIDGE EVENT RECEIVED =====")
    print(json.dumps(event, indent=2))

    # Get S3 bucket name dynamically
    bucket_name = event["detail"]["bucket"]["name"]

    # Get S3 object key dynamically
    object_key = event["detail"]["object"]["key"]

    print("===== S3 DETAILS =====")
    print(f"Bucket Name : {bucket_name}")
    print(f"Object Key  : {object_key}")

    # Start Glue Job
    response = glue.start_job_run(
        JobName=GLUE_JOB_NAME,
        Arguments={
            "--bucket_name": bucket_name,
            "--object_key": object_key
        }
    )

    job_run_id = response["JobRunId"]

    print("===== GLUE JOB STARTED =====")
    print(f"Glue Job Name  : {GLUE_JOB_NAME}")
    print(f"Glue Job Run ID: {job_run_id}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Glue job started successfully",
            "bucket_name": bucket_name,
            "object_key": object_key,
            "job_run_id": job_run_id
        })
    }
