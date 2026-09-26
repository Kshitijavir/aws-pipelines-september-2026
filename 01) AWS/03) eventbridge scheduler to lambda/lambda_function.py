import json
from datetime import datetime, timezone


def lambda_handler(event, context):

    current_time = datetime.now(timezone.utc)

    print("===== EVENTBRIDGE SCHEDULE TRIGGERED =====")
    print(f"Lambda execution time : {current_time}")
    print("Message               : Lambda executed successfully")
    print("Trigger               : EventBridge Scheduler")
    print("Schedule              : rate(1 minute)")

    print("Event received from EventBridge:")
    print(json.dumps(event, indent=2))

    return {
        "statusCode": 200,
        "body": json.dumps("Lambda executed successfully")
    }
