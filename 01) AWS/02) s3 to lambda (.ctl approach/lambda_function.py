import json
import boto3
from urllib.parse import unquote_plus

s3 = boto3.client("s3")


def lambda_handler(event, context):

    print("===== CONTROL FILE RECEIVED =====")

    # Get bucket name from S3 event
    bucket_name = event["Records"][0]["s3"]["bucket"]["name"]

    # Get control file name
    raw_key = event["Records"][0]["s3"]["object"]["key"]
    control_file = unquote_plus(raw_key)

    print(f"Bucket Name  : {bucket_name}")
    print(f"Control File : {control_file}")

    print("===== FILES IN BUCKET =====")

    # List objects in the bucket
    response = s3.list_objects_v2(
        Bucket=bucket_name
    )

    if "Contents" in response:

        for obj in response["Contents"]:

            file_name = obj["Key"]
            file_size = obj["Size"]

            print(f"File Name : {file_name}")
            print(f"File Size : {file_size} bytes")
            print("-------------------------")

    else:
        print("No files found in bucket.")

    return {
        "statusCode": 200,
        "body": json.dumps("Control file processed successfully")
    }
