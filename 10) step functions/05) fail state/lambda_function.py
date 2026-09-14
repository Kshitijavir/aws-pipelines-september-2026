def lambda_handler(event, context):

    print("====================================")
    print("       VALIDATION LAMBDA STARTED")
    print("====================================")

    print(f"Received event: {event}")

    student = event.get("student")
    marks = event.get("marks")

    print(f"Student Name : {student}")
    print(f"Student Marks: {marks}")

    print("Checking student data...")

    if student is None:
        print("ERROR: Student name is missing.")

        return {
            "valid": False,
            "reason": "Student name is missing"
        }

    if marks is None:
        print("ERROR: Marks are missing.")

        return {
            "valid": False,
            "reason": "Marks are missing"
        }

    if marks < 0 or marks > 10:
        print("ERROR: Marks are invalid.")

        return {
            "valid": False,
            "reason": "Marks must be between 0 and 10"
        }

    print("Student data is valid.")

    result = {
        "valid": True,
        "student": student,
        "marks": marks,
        "message": "Student data is valid"
    }

    print(f"Returning result: {result}")

    print("====================================")
    print("       VALIDATION LAMBDA FINISHED")
    print("====================================")

    return result
