def lambda_handler(event, context):

    print("===================================")
    print("Lambda Started")
    print("===================================")

    print("Received event:")
    print(event)

    glue_job_name = event.get("glue_job_name")
    status = event.get("status")

    print(f"Glue Job Name : {glue_job_name}")
    print(f"Glue Job Status : {status}")

    if status == "SUCCESS":

        print("Glue Job completed successfully.")

    elif status == "FAILED":

        print("Glue Job failed.")

    else:

        print("Unknown Glue Job status.")

    print("===================================")
    print("Lambda Completed")
    print("===================================")

    return {
        "glue_job_name": glue_job_name,
        "status": status
    }
