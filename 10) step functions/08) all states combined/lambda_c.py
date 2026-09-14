from datetime import datetime
from zoneinfo import ZoneInfo


def lambda_handler(event, context):

    print("====================================")
    print("          LAMBDA C STARTED")
    print("====================================")

    print(f"Received event: {event}")

    student = event["student"]
    marks = event["marks"]

    ist_time = datetime.now(
        ZoneInfo("Asia/Kolkata")
    )

    print(f"Lambda      : Lambda C")
    print(f"Student     : {student}")
    print(f"Marks       : {marks}")
    print(
        f"Hitting Time (IST): "
        f"{ist_time.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    )

    print("Lambda C is processing the request...")

    result = {
        "lambda": "Lambda C",
        "student": student,
        "status": "SUCCESS",
        "time_ist": ist_time.strftime(
            "%Y-%m-%d %H:%M:%S %Z"
        )
    }

    print(f"Returning result: {result}")

    print("========== LAMBDA C FINISHED ==========")

    return result
