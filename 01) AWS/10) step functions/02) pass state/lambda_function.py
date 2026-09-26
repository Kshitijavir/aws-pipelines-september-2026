def lambda_handler(event, context):

    print("========== LAMBDA STARTED ==========")

    print(f"Received event: {event}")

    student = event["student"]
    marks = event["marks"]
    message = event["message"]

    print(f"Student Name : {student}")
    print(f"Student Marks: {marks}")
    print(f"Message      : {message}")

    result = {
        "student": student,
        "marks": marks,
        "status": "PROCESSED",
        "message": "Student processing completed"
    }

    print(f"Returning result: {result}")

    print("========== LAMBDA FINISHED ==========")

    return result
