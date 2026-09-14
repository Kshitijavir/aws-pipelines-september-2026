from datetime import datetime
from zoneinfo import ZoneInfo


def lambda_handler(event, context):

    print("====================================")
    print("       STUDENT LAMBDA STARTED")
    print("====================================")

    print(f"Received student data: {event}")

    student_name = event["name"]
    marks = event["marks"]

    # Current IST time
    ist_time = datetime.now(
        ZoneInfo("Asia/Kolkata")
    )

    print(f"Student Name : {student_name}")
    print(f"Student Marks: {marks}")
    print(
        f"Processing Time (IST): "
        f"{ist_time.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    )

    print("Checking student result...")

    if marks > 7:

        status = "PASS"

        print(
            f"{student_name} has PASSED "
            f"with {marks} marks."
        )

    else:

        status = "FAIL"

        print(
            f"{student_name} has FAILED "
            f"with {marks} marks."
        )

    result = {
        "student": student_name,
        "marks": marks,
        "status": status,
        "processed_time_ist": ist_time.strftime(
            "%Y-%m-%d %H:%M:%S %Z"
        )
    }

    print(f"Returning result: {result}")

    print("====================================")
    print("       STUDENT LAMBDA FINISHED")
    print("====================================")

    return result
