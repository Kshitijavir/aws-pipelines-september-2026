def lambda_handler(event, context):

    print("====================================")
    print("       STUDENT LAMBDA STARTED")
    print("====================================")

    print(f"Received event from Step Functions: {event}")

    student = event["student"]
    marks = event["marks"]

    print(f"Student Name : {student}")
    print(f"Student Marks: {marks}")

    print("Checking student result...")

    if marks > 7:

        status = "PASS"
        message = f"{student} passed with {marks} marks"

        print("Marks are greater than 7.")
        print("Student result: PASS")

    else:

        status = "FAIL"
        message = f"{student} failed with {marks} marks"

        print("Marks are 7 or less.")
        print("Student result: FAIL")

    result = {
        "student": student,
        "marks": marks,
        "status": status,
        "message": message
    }

    print(f"Returning result to Step Functions: {result}")

    print("====================================")
    print("       STUDENT LAMBDA FINISHED")
    print("====================================")

    return result
