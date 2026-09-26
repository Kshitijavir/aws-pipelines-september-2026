def lambda_handler(event, context):

    print("========== PASS LAMBDA STARTED ==========")

    print(f"Received event: {event}")

    student = event["student"]
    marks = event["marks"]

    print(f"Student Name : {student}")
    print(f"Student Marks: {marks}")

    print(f"Checking PASS condition...")
    print(f"Marks received = {marks}")

    print(f"Student {student} has PASSED.")

    result = {
        "student": student,
        "status": "PASS",
        "message": f"{student} passed with {marks} marks"
    }

    print(f"Returning result: {result}")

    print("========== PASS LAMBDA FINISHED ==========")

    return result
