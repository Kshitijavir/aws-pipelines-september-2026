def lambda_handler(event, context):

    hit_number = event.get("hit_number")

    if hit_number == 1:
        message = "First Hit"

    elif hit_number == 2:
        message = "Second Hit"

    elif hit_number == 3:
        message = "Third Hit"

    else:
        message = "Unknown Hit"

    print("================================")
    print(f"Lambda executed: {message}")
    print(f"Hit Number: {hit_number}")
    print("================================")

    return {
        "statusCode": 200,
        "hit_number": hit_number,
        "message": message
    }
