import urllib.parse

import boto3

glue = boto3.client("glue")

# The Glue job name is set here, directly in the code.
# Change this line if your Glue job is named something else.
GLUE_JOB_NAME = "YOUR GLUE JOB NAME"


def lambda_handler(event, context):

    print("=" * 50)
    print("STARTING GLUE JOB")
    print("=" * 50)

    # The whole EventBridge event arrives here, because the state machine
    # forwards it with Payload.$: "$"
    detail = event["detail"]

    source_bucket = detail["bucket"]["name"]

    source_key = urllib.parse.unquote_plus(
        detail["object"]["key"]
    )

    print(f"Glue Job      : {GLUE_JOB_NAME}")
    print(f"Source Bucket : {source_bucket}")
    print(f"Source Key    : {source_key}")

    # ---------------------------------------------------------
    # Start the Glue job
    #
    # We only START it here. We do not wait — Step Functions polls the job
    # separately, so the Lambda returns immediately and nothing is billed
    # for sitting idle.
    # ---------------------------------------------------------

    response = glue.start_job_run(
        JobName=GLUE_JOB_NAME,
        Arguments={
            "--source_bucket": source_bucket,
            "--source_key": source_key
        }
    )

    job_run_id = response["JobRunId"]

    print(f"Job Run ID    : {job_run_id}")
    print("=" * 50)

    # Step Functions reads glue_job_name and job_run_id out of this return
    # value to poll the job. Everything returned here becomes the state
    # machine's input for the next state.
    return {
        "statusCode": 200,
        "glue_job_name": GLUE_JOB_NAME,
        "job_run_id": job_run_id,
        "source_bucket": source_bucket,
        "source_key": source_key
    }
