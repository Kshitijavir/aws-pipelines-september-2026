from datetime import datetime
from zoneinfo import ZoneInfo


def lambda_handler(event, context):

    print("====================================")
    print("       MAP LAMBDA STARTED")
    print("====================================")

    print(f"Received student event: {event}")

    student = event["name"]
    marks = event["marks"]

    ist_time = datetime.now(
        ZoneInfo("Asia/Kolkata")
    )

    print(f"Student     : {student}")
    print(f"Marks       : {marks}")
    print(
        f"Processing Time (IST): "
        f"{ist_time.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    )

    if marks >= 7:

        status = "PASS"

        print(
            f"Result: {student} PASSED with {marks} marks."
        )

    else:

        status = "FAIL"

        print(
            f"Result: {student} FAILED with {marks} marks."
        )

    result = {
        "student": student,
        "marks": marks,
        "status": status,
        "processed_time_ist": ist_time.strftime(
            "%Y-%m-%d %H:%M:%S %Z"
        )
    }

    print(f"Returning result: {result}")

    print("========== MAP LAMBDA FINISHED ==========")

    return result
