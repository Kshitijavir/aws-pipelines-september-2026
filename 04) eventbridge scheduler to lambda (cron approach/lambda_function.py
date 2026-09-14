import json
from datetime import datetime, timezone


def lambda_handler(event, context):

    current_time = datetime.now(timezone.utc)

    print("===== EVENTBRIDGE CRON TRIGGERED =====")

    print(f"Lambda execution time : {current_time}")

    print("Trigger  : EventBridge Scheduler")

    print("Schedule : Every day at 6 PM")

    print("Message  : Lambda executed successfully")

    print("Event received:")
    print(json.dumps(event, indent=2))

    return {
        "statusCode": 200,
        "body": json.dumps("Lambda executed successfully")
    }
