def lambda_handler(event, context):

    print("========== FAIL LAMBDA STARTED ==========")

    print(f"Received event: {event}")

    student = event["student"]
    marks = event["marks"]

    print(f"Student Name : {student}")
    print(f"Student Marks: {marks}")

    print(f"Checking PASS condition...")
    print(f"Marks received = {marks}")

    print(f"Student {student} has FAILED.")

    result = {
        "student": student,
        "status": "FAIL",
        "message": f"{student} failed with {marks} marks"
    }

    print(f"Returning result: {result}")

    print("========== FAIL LAMBDA FINISHED ==========")

    return result
