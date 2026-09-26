from datetime import datetime
from zoneinfo import ZoneInfo


def lambda_handler(event, context):

    print("====================================")
    print("       LAMBDA A STARTED")
    print("====================================")

    print(f"Received event: {event}")

    # Get current IST time
    ist_time = datetime.now(ZoneInfo("Asia/Kolkata"))

    print(f"Lambda Name : Lambda A")
    print(f"Execution Time (IST): {ist_time.strftime('%Y-%m-%d %H:%M:%S %Z')}")

    print("Lambda A is processing the request...")

    result = {
        "lambda": "Lambda A",
        "status": "SUCCESS",
        "execution_time_ist": ist_time.strftime(
            "%Y-%m-%d %H:%M:%S %Z"
        )
    }

    print(f"Returning result: {result}")

    print("====================================")
    print("       LAMBDA A FINISHED")
    print("====================================")

    return result
