from datetime import datetime
from zoneinfo import ZoneInfo


def lambda_handler(event, context):

    print("====================================")
    print("       LAMBDA B STARTED")
    print("====================================")

    print(f"Received event: {event}")

    ist_time = datetime.now(ZoneInfo("Asia/Kolkata"))

    print(f"Lambda Name : Lambda B")
    print(f"Execution Time (IST): {ist_time.strftime('%Y-%m-%d %H:%M:%S %Z')}")

    print("Lambda B is processing the request...")

    result = {
        "lambda": "Lambda B",
        "status": "SUCCESS",
        "execution_time_ist": ist_time.strftime(
            "%Y-%m-%d %H:%M:%S %Z"
        )
    }

    print(f"Returning result: {result}")

    print("====================================")
    print("       LAMBDA B FINISHED")
    print("====================================")

    return result
