import os
import boto3
from datetime import datetime, timezone


# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

REGION = "us-east-1"

SENDER = "no-reply@kshitijaws.site"

RECIPIENTS = [
    "kshitijjavir110@gmail.com",
    "kshitijjavir111@gmail.com",
]

LAMBDA_FUNCTION_NAME = "test-ses-lambda"


# ─────────────────────────────────────────────────────────────────────────────
# File Paths
# ─────────────────────────────────────────────────────────────────────────────

BASE_DIR = os.path.dirname(__file__)

HTML_TEMPLATE_PATH = os.path.join(
    BASE_DIR,
    "email.html"
)

CSS_TEMPLATE_PATH = os.path.join(
    BASE_DIR,
    "email.css"
)


# ─────────────────────────────────────────────────────────────────────────────
# AWS SES Client
# ─────────────────────────────────────────────────────────────────────────────

ses = boto3.client(
    "ses",
    region_name=REGION
)


# ─────────────────────────────────────────────────────────────────────────────
# Load HTML + CSS
# ─────────────────────────────────────────────────────────────────────────────

def load_html_template():
    """
    Load email.html and email.css.

    CSS is injected inside the HTML before the email
    is sent through Amazon SES.
    """

    with open(
        HTML_TEMPLATE_PATH,
        "r",
        encoding="utf-8"
    ) as html_file:

        html = html_file.read()

    with open(
        CSS_TEMPLATE_PATH,
        "r",
        encoding="utf-8"
    ) as css_file:

        css = css_file.read()

    html = html.replace(
        "</head>",
        f"<style>{css}</style></head>"
    )

    return html


# ─────────────────────────────────────────────────────────────────────────────
# Build HTML Email
# ─────────────────────────────────────────────────────────────────────────────

def build_html_email(
    status,
    trigger,
    error_type,
    error_message,
    execution_time
):

    html = load_html_template()

    # ─────────────────────────────────────────────────────────────────────────
    # SUCCESS
    # ─────────────────────────────────────────────────────────────────────────

    if status == "SUCCESS":

        status_class = "success"

        status_icon = "✓"

        status_title = "Lambda Execution Successful"

        status_description = (
            "AWS Lambda completed successfully and dispatched "
            "this notification through Amazon SES."
        )

        notification_title = "Notification Information"

        notification_message = (
            "The Lambda function executed successfully and "
            "Amazon SES accepted the email for delivery."
        )

        error_section = ""

    # ─────────────────────────────────────────────────────────────────────────
    # FAILED
    # ─────────────────────────────────────────────────────────────────────────

    else:

        status_class = "failed"

        status_icon = "!"

        status_title = "Lambda Execution Failed"

        status_description = (
            "AWS Lambda reported a failure during execution. "
            "Review the failure information below."
        )

        notification_title = "Failure Notification"

        notification_message = (
            "The Lambda execution reported a failure. "
            "Review the error details and CloudWatch logs "
            "to investigate the issue."
        )

        error_section = f"""
        <div class="section-title error-heading">
            Failure Details
        </div>

        <div class="error-card">

            <div class="error-row">

                <div class="error-label">
                    Error Type
                </div>

                <div class="error-value">
                    {error_type}
                </div>

            </div>

            <div class="error-row last-row">

                <div class="error-label">
                    Error Message
                </div>

                <div class="error-value">
                    {error_message}
                </div>

            </div>

        </div>
        """

    # ─────────────────────────────────────────────────────────────────────────
    # Replace HTML placeholders
    # ─────────────────────────────────────────────────────────────────────────

    replacements = {

        "{{STATUS}}": status,

        "{{STATUS_CLASS}}": status_class,

        "{{STATUS_ICON}}": status_icon,

        "{{STATUS_TITLE}}": status_title,

        "{{STATUS_DESCRIPTION}}": status_description,

        "{{LAMBDA_FUNCTION}}": LAMBDA_FUNCTION_NAME,

        "{{REGION}}": REGION,

        "{{TRIGGER}}": trigger,

        "{{EXECUTION_TIME}}": execution_time,

        "{{NOTIFICATION_TITLE}}": notification_title,

        "{{NOTIFICATION_MESSAGE}}": notification_message,

        "{{ERROR_SECTION}}": error_section
    }

    for placeholder, value in replacements.items():

        html = html.replace(
            placeholder,
            str(value)
        )

    return html


# ─────────────────────────────────────────────────────────────────────────────
# Plain Text Fallback
# ─────────────────────────────────────────────────────────────────────────────

def build_text_fallback(
    status,
    trigger,
    error_type,
    error_message,
    execution_time
):

    text = (
        "AWS LAMBDA NOTIFICATION\n"
        "=======================\n\n"

        f"STATUS: {status}\n\n"

        "EXECUTION DETAILS\n"
        "-----------------\n"

        f"Lambda Function : {LAMBDA_FUNCTION_NAME}\n"
        f"AWS Region      : {REGION} (N. Virginia)\n"
        "Service         : Amazon SES\n"
        f"Trigger         : {trigger}\n"
        f"Status          : {status}\n"
        f"Execution Time  : {execution_time}\n"
    )

    if status == "FAILED":

        text += (
            "\n"
            "FAILURE DETAILS\n"
            "---------------\n"

            f"Error Type      : {error_type}\n"
            f"Error Message   : {error_message}\n"
        )

    text += (
        "\n"
        "--\n"
        "AWS Lambda | Amazon SES\n"
        "This is an automated notification.\n"
        "Please do not reply to this message.\n"
    )

    return text


# ─────────────────────────────────────────────────────────────────────────────
# Lambda Handler
# ─────────────────────────────────────────────────────────────────────────────

def lambda_handler(event, context):

    try:

        print("=" * 70)
        print("AWS LAMBDA → AMAZON SES NOTIFICATION")
        print("=" * 70)

        # ─────────────────────────────────────────────────────────────────────
        # Read Test JSON
        # ─────────────────────────────────────────────────────────────────────

        status = str(
            event.get(
                "status",
                "SUCCESS"
            )
        ).upper()

        trigger = event.get(
            "trigger",
            "Manual Test Invocation"
        )

        error_type = event.get(
            "errorType",
            "LambdaExecutionError"
        )

        error_message = event.get(
            "errorMessage",
            "The Lambda function reported an execution failure."
        )

        # Only SUCCESS or FAILED are allowed
        if status not in [
            "SUCCESS",
            "FAILED"
        ]:

            raise ValueError(
                "status must be either SUCCESS or FAILED"
            )

        # ─────────────────────────────────────────────────────────────────────
        # Execution Information
        # ─────────────────────────────────────────────────────────────────────

        execution_time = datetime.now(
            timezone.utc
        ).strftime(
            "%Y-%m-%d %H:%M:%S UTC"
        )

        # ─────────────────────────────────────────────────────────────────────
        # Dynamic Subject
        # ─────────────────────────────────────────────────────────────────────

        if status == "SUCCESS":

            subject = (
                "AWS Lambda Notification - "
                "Execution Successful"
            )

        else:

            subject = (
                "AWS Lambda Alert - "
                "Execution Failed"
            )

        # ─────────────────────────────────────────────────────────────────────
        # Build Email
        # ─────────────────────────────────────────────────────────────────────

        html_body = build_html_email(
            status=status,
            trigger=trigger,
            error_type=error_type,
            error_message=error_message,
            execution_time=execution_time
        )

        text_body = build_text_fallback(
            status=status,
            trigger=trigger,
            error_type=error_type,
            error_message=error_message,
            execution_time=execution_time
        )

        # ─────────────────────────────────────────────────────────────────────
        # Logs
        # ─────────────────────────────────────────────────────────────────────

        print(f"Status          : {status}")
        print(f"Lambda Function : {LAMBDA_FUNCTION_NAME}")
        print(f"Region          : {REGION}")
        print(f"Trigger         : {trigger}")
        print(f"Sender          : {SENDER}")
        print(f"Recipients      : {RECIPIENTS}")
        print(f"Subject         : {subject}")

        if status == "FAILED":

            print(f"Error Type      : {error_type}")
            print(f"Error Message   : {error_message}")

        # ─────────────────────────────────────────────────────────────────────
        # Send Email
        # ─────────────────────────────────────────────────────────────────────

        response = ses.send_email(

            Source=SENDER,

            Destination={
                "ToAddresses": RECIPIENTS
            },

            Message={

                "Subject": {
                    "Data": subject,
                    "Charset": "UTF-8"
                },

                "Body": {

                    "Text": {
                        "Data": text_body,
                        "Charset": "UTF-8"
                    },

                    "Html": {
                        "Data": html_body,
                        "Charset": "UTF-8"
                    }
                }
            },

            ReplyToAddresses=[
                SENDER
            ]
        )

        message_id = response["MessageId"]

        # ─────────────────────────────────────────────────────────────────────
        # Success Response
        # ─────────────────────────────────────────────────────────────────────

        print("=" * 70)
        print("EMAIL SENT SUCCESSFULLY")
        print("=" * 70)

        print(f"Notification Status : {status}")
        print(f"SES MessageId       : {message_id}")

        print("=" * 70)

        return {

            "statusCode": 200,

            "body": {

                "message": "Email sent successfully through Amazon SES",

                "notificationStatus": status,

                "messageId": message_id
            }
        }

    except Exception as error:

        print("=" * 70)
        print("ERROR: FAILED TO SEND SES NOTIFICATION")
        print("=" * 70)

        print(f"Error: {str(error)}")

        raise
