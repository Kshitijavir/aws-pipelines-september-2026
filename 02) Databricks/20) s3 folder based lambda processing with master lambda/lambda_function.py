import json
import boto3
import os
from urllib.parse import unquote_plus
from datetime import datetime, timezone


# AWS clients
lambda_client = boto3.client("lambda")
ses_client = boto3.client("ses")


def load_file(file_name):
    """
    Read a file from the Lambda deployment package.
    """

    file_path = os.path.join(
        os.path.dirname(__file__),
        "email",
        file_name
    )

    print(f"Loading file: {file_path}")

    with open(
        file_path,
        "r",
        encoding="utf-8"
    ) as file:
        return file.read()


def send_email(
    config,
    status,
    bucket_name,
    folder_name,
    file_name,
    lambda_name,
    message
):
    """
    Build and send SUCCESS or FAILURE email using SES.
    """

    print("Preparing email...")

    # -------------------------------------------------
    # Email configuration
    # -------------------------------------------------

    email_config = config["email"]

    sender = email_config["sender"]
    recipient = email_config["recipient"]
    subject_prefix = email_config["subject_prefix"]

    # -------------------------------------------------
    # Load email wrapper
    # -------------------------------------------------

    email_html = load_file("email.html")

    # -------------------------------------------------
    # Select SUCCESS / FAILURE template
    # -------------------------------------------------

    if status == "SUCCESS":

        template = load_file(
            "success_template.html"
        )

        subject = (
            f"{subject_prefix} - SUCCESS - "
            f"{lambda_name}"
        )

    else:

        template = load_file(
            "failure_template.html"
        )

        subject = (
            f"{subject_prefix} - FAILED - "
            f"{lambda_name}"
        )

    # -------------------------------------------------
    # Current time
    # -------------------------------------------------

    completed_time = datetime.now(
        timezone.utc
    ).strftime(
        "%d %b %Y, %I:%M:%S %p UTC"
    )

    # -------------------------------------------------
    # Replace placeholders
    # -------------------------------------------------

    template = template.replace(
        "{{BUCKET_NAME}}",
        bucket_name
    )

    template = template.replace(
        "{{FOLDER_NAME}}",
        folder_name
    )

    template = template.replace(
        "{{FILE_NAME}}",
        file_name
    )

    template = template.replace(
        "{{LAMBDA_NAME}}",
        lambda_name
    )

    template = template.replace(
        "{{STATUS}}",
        status
    )

    template = template.replace(
        "{{MESSAGE}}",
        message
    )

    template = template.replace(
        "{{COMPLETED_TIME}}",
        completed_time
    )

    # -------------------------------------------------
    # Insert SUCCESS / FAILURE content
    # into the main email HTML
    # -------------------------------------------------

    email_html = email_html.replace(
        "{{EMAIL_CONTENT}}",
        template
    )

    # -------------------------------------------------
    # Send email using SES
    # -------------------------------------------------

    print(
        f"Sending {status} email..."
    )

    print(
        f"From: {sender}"
    )

    print(
        f"To: {recipient}"
    )

    response = ses_client.send_email(

        Source=sender,

        Destination={
            "ToAddresses": [
                recipient
            ]
        },

        Message={

            "Subject": {
                "Data": subject,
                "Charset": "UTF-8"
            },

            "Body": {

                "Html": {
                    "Data": email_html,
                    "Charset": "UTF-8"
                }

            }

        }
    )

    print(
        f"Email sent successfully."
    )

    print(
        f"SES Message ID: "
        f"{response['MessageId']}"
    )


def lambda_handler(event, context):

    print("===================================")
    print("Master Lambda started")
    print("===================================")

    # -------------------------------------------------
    # Load config.json
    # -------------------------------------------------

    config_path = os.path.join(
        os.path.dirname(__file__),
        "config.json"
    )

    print(
        f"Reading config from: {config_path}"
    )

    with open(
        config_path,
        "r",
        encoding="utf-8"
    ) as file:

        config = json.load(file)

    print(
        "Config loaded successfully"
    )

    bucket_name = config["bucket_name"]
    folders = config["folders"]

    # -------------------------------------------------
    # Read S3 event
    # -------------------------------------------------

    record = event["Records"][0]

    bucket = record["s3"]["bucket"]["name"]

    object_key = unquote_plus(
        record["s3"]["object"]["key"]
    )

    print(
        f"Bucket from event: {bucket}"
    )

    print(
        f"File uploaded: {object_key}"
    )

    # -------------------------------------------------
    # Detect folder
    # -------------------------------------------------

    folder_name = object_key.split("/")[0]

    file_name = object_key.split("/")[-1]

    print(
        f"Detected folder: {folder_name}"
    )

    print(
        f"Detected file: {file_name}"
    )

    # -------------------------------------------------
    # Check configuration
    # -------------------------------------------------

    if folder_name not in folders:

        print(
            f"No configuration found "
            f"for folder: {folder_name}"
        )

        return {
            "statusCode": 400,
            "message": (
                f"No Lambda configured "
                f"for folder {folder_name}"
            )
        }

    # -------------------------------------------------
    # Get Lambda configuration
    # -------------------------------------------------

    folder_config = folders[folder_name]

    s3_path = folder_config["s3_path"]

    lambda_name = folder_config["lambda_name"]

    print("-----------------------------------")

    print(
        f"Selected Lambda: {lambda_name}"
    )

    print(
        f"Selected Folder: {folder_name}"
    )

    print(
        f"Selected File: {file_name}"
    )

    print("-----------------------------------")

    # -------------------------------------------------
    # Build payload for Sub Lambda
    # -------------------------------------------------

    payload = {

        "bucket_name": bucket_name,

        "folder": folder_name,

        "s3_path": s3_path,

        "file_key": object_key,

        "file_name": file_name

    }

    # -------------------------------------------------
    # Invoke Sub Lambda
    # -------------------------------------------------

    try:

        print(
            f"Invoking {lambda_name}..."
        )

        response = lambda_client.invoke(

            FunctionName=lambda_name,

            # IMPORTANT:
            # Master waits for Sub Lambda
            InvocationType="RequestResponse",

            Payload=json.dumps(
                payload
            ).encode("utf-8")

        )

        print(
            "Sub Lambda response received."
        )

        # -------------------------------------------------
        # Check Sub Lambda failure
        # -------------------------------------------------

        if response.get("FunctionError"):

            print(
                f"Sub Lambda failed."
            )

            print(
                f"FunctionError: "
                f"{response['FunctionError']}"
            )

            response_payload = (
                response["Payload"]
                .read()
                .decode("utf-8")
            )

            print(
                f"Failure response:"
            )

            print(
                response_payload
            )

            # -------------------------------------------------
            # Send FAILURE email
            # -------------------------------------------------

            send_email(

                config=config,

                status="FAILED",

                bucket_name=bucket_name,

                folder_name=folder_name,

                file_name=file_name,

                lambda_name=lambda_name,

                message=response_payload

            )

            return {

                "statusCode": 500,

                "message": (
                    f"{lambda_name} failed"
                )

            }

        # -------------------------------------------------
        # Sub Lambda SUCCESS
        # -------------------------------------------------

        response_payload = (
            response["Payload"]
            .read()
            .decode("utf-8")
        )

        print(
            "Sub Lambda completed successfully."
        )

        print(
            f"Success response:"
        )

        print(
            response_payload
        )

        # -------------------------------------------------
        # Send SUCCESS email
        # -------------------------------------------------

        send_email(

            config=config,

            status="SUCCESS",

            bucket_name=bucket_name,

            folder_name=folder_name,

            file_name=file_name,

            lambda_name=lambda_name,

            message=response_payload

        )

        print(
            "SUCCESS email sent."
        )

        # -------------------------------------------------
        # Return Master Lambda response
        # -------------------------------------------------

        return {

            "statusCode": 200,

            "message": (
                f"{lambda_name} completed "
                f"successfully"
            )

        }

    # -------------------------------------------------
    # Unexpected Master Lambda error
    # -------------------------------------------------

    except Exception as e:

        print(
            "Unexpected error occurred."
        )

        print(
            str(e)
        )

        # -------------------------------------------------
        # Try to send FAILURE email
        # -------------------------------------------------

        try:

            send_email(

                config=config,

                status="FAILED",

                bucket_name=bucket_name,

                folder_name=folder_name,

                file_name=file_name,

                lambda_name=lambda_name,

                message=str(e)

            )

        except Exception as email_error:

            print(
                "Could not send failure email."
            )

            print(
                str(email_error)
            )

        # Re-raise original error
        raise