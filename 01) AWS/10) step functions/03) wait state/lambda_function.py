def lambda_handler(event, context):

    print("====================================")
    print("        LAMBDA STARTED")
    print("====================================")

    print(f"Received event: {event}")

    count = event.get("count", 0)

    print(f"Execution count received: {count}")

    if count == 1:
        print("This is the FIRST time Lambda was called by Step Functions.")

    elif count == 2:
        print("This is the SECOND time Lambda was called by Step Functions.")

    elif count == 3:
        print("This is the THIRD time Lambda was called by Step Functions.")

    else:
        print("Unknown execution count.")

    result = {
        "count": count,
        "message": f"Lambda was called {count} time(s)"
    }

    print(f"Returning result: {result}")

    print("====================================")
    print("        LAMBDA FINISHED")
    print("====================================")

    return result
