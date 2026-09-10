import json
from urllib.parse import unquote_plus


def lambda_handler(event, context):

    print("===== S3 FILE UPLOAD EVENT =====")

    print("Full Event:")
    print(json.dumps(event, indent=2))

    for record in event.get("Records", []):

        bucket_name = record["s3"]["bucket"]["name"]

        raw_key = record["s3"]["object"]["key"]
        file_name = unquote_plus(raw_key)

        file_size = record["s3"]["object"].get("size")

        event_name = record.get("eventName")

        event_time = record.get("eventTime")

        print("----- File Metadata -----")

        print(f"Bucket Name : {bucket_name}")
        print(f"File Name   : {file_name}")
        print(f"File Size   : {file_size} bytes")
        print(f"Event Name  : {event_name}")
        print(f"Event Time  : {event_time}")

    return {
        "statusCode": 200,
        "body": json.dumps("S3 event processed successfully")
    }
