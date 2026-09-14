import json


def lambda_handler(event, context):

    print("===== S3 EVENT THROUGH EVENTBRIDGE =====")

    print("Full Event:")
    print(json.dumps(event, indent=2))

    print("----- Event Details -----")

    print(f"Event Type : {event.get('detail-type')}")
    print(f"Source     : {event.get('source')}")
    print(f"Event Time : {event.get('time')}")

    detail = event.get("detail", {})

    bucket = detail.get("bucket", {})
    obj = detail.get("object", {})

    print("----- S3 File Details -----")

    print(f"Bucket Name : {bucket.get('name')}")
    print(f"File Name   : {obj.get('key')}")
    print(f"File Size   : {obj.get('size')} bytes")

    return {
        "statusCode": 200,
        "body": json.dumps("S3 EventBridge event processed successfully")
    }
