# ─────────────────────────────────────────────────────────────────────────────
# 64) PIPELINE : S3 -> EventBridge -> Step Functions -> Snowflake SP1 -> SP2
#
# JOB      : Sends the SUCCESS or FAILURE email for the whole pipeline run.
#            Step Functions calls this function as the LAST state, whichever
#            way the run ended.
#
# FUNCTION : snowflake-pipeline-email-lambda
# RUNTIME  : Python 3.12
# HANDLER  : email_lambda.lambda_handler
#
# LAYER    : None. This function only uses boto3, which is already in the
#            Lambda runtime.
#
# ROLE     : SnowflakeStepFunctionsPracticeRole
#            - AWSLambdaBasicExecutionRole  (CloudWatch logs)
#            - AmazonSESFullAccess          (send the email)
#
# SES      : The sender domain and every recipient must be verified in
#            Amazon SES (us-east-1) while the account is in the sandbox.
# ─────────────────────────────────────────────────────────────────────────────

import json
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

LAMBDA_FUNCTION_NAME = "snowflake-pipeline-email-lambda"

PIPELINE_NAME = "S3 -> EventBridge -> Step Functions -> Snowflake SP1 -> SP2"


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
#
# CSS is injected inside the HTML before the email is sent through Amazon SES.
# ─────────────────────────────────────────────────────────────────────────────

def load_html_template():

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
# Flatten the Step Functions State
#
# Every Snowflake Lambda in this pipeline returns "statusCode" and "body", so
# the values needed by the email can sit at the top level or inside "body".
# This merges both into one dictionary.
# ─────────────────────────────────────────────────────────────────────────────

def flatten_detail(detail):

    if isinstance(detail, str):

        try:
            detail = json.loads(detail)

        except ValueError:
            return {}

    if not isinstance(detail, dict):
        return {}

    values = dict(detail)

    body = values.get("body")

    if isinstance(body, str):

        try:
            body = json.loads(body)

        except ValueError:
            body = {}

    if isinstance(body, dict):
        values.update(body)

    return values


# ─────────────────────────────────────────────────────────────────────────────
# HTML Builders
# ─────────────────────────────────────────────────────────────────────────────

def build_detail_rows(rows):

    html = ""

    for label, value in rows:

        if value is None or value == "":
            continue

        if value is True:
            value = "Yes"

        if value is False:
            value = "No"

        html += (
            '<div class="detail-row">'
            f'<div class="detail-label">{label}</div>'
            f'<div class="detail-value">{value}</div>'
            "</div>"
        )

    return html


def build_error_section(values, status):

    if status != "FAILED":
        return ""

    error_type = values.get("Error") or values.get("errorType") or "PipelineError"

    error_message = (
        values.get("Cause")
        or values.get("errorMessage")
        or values.get("sp2_error")
        or values.get("sp1_error")
        or values.get("sp1_message")
        or "The pipeline reported a failure. Check the CloudWatch logs of the "
           "Step Functions execution for the full trace."
    )

    return (
        '<div class="section-title">Failure Details</div>'
        '<div class="error-card">'
        '<div class="error-row">'
        '<div class="error-label">Error Type</div>'
        f'<div class="error-value">{error_type}</div>'
        "</div>"
        '<div class="error-row">'
        '<div class="error-label">Error Message</div>'
        f'<div class="error-value">{error_message}</div>'
        "</div>"
        "</div>"
    )


def build_html_email(status, values, execution_time):

    html = load_html_template()

    if status == "SUCCESS":

        status_class = "success"
        status_icon = "&#10003;"
        status_title = "Pipeline Run Successful"
        status_description = (
            "The S3 file was loaded by SP1 and transformed by SP2. "
            "The dimensions, the fact table and the audit tables are updated."
        )
        notification_title = "Everything Completed"
        notification_message = (
            "SP1 loaded the file into STAGING_ORDERS and SP2 loaded "
            "DIM_CUSTOMER, DIM_PRODUCT and FACT_SALES. Amazon SES accepted "
            "this email for delivery."
        )

    else:

        status_class = "failed"
        status_icon = "&#10005;"
        status_title = "Pipeline Run Failed"
        status_description = (
            "The pipeline stopped before it finished. The details below show "
            "how far the run got."
        )
        notification_title = "Action Needed"
        notification_message = (
            "Open the Step Functions execution history to see which state "
            "failed, then check the CloudWatch logs of the Lambda function "
            "for that state."
        )

    detail_rows = build_detail_rows([

        ("Pipeline", PIPELINE_NAME),
        ("Region", REGION),
        ("Trigger", values.get("trigger") or "Step Functions"),
        ("S3 File", values.get("sp1_file_name")),
        ("SP1 Procedure", "SP1_LOAD_STAGING"),
        ("SP1 Query ID", values.get("sp1_query_id")),
        ("SP1 Status", values.get("sp1_status")),
        ("SP1 Rows Loaded", values.get("sp1_rows_loaded")),
        ("SP2 Procedure", "SP2_LOAD_STAR_SCHEMA"),
        ("SP2 Status", values.get("sp2_status")),
        ("SP2 Rows Read", values.get("sp2_rows_read")),
        ("Customers Loaded", values.get("sp2_customers_loaded")),
        ("Products Loaded", values.get("sp2_products_loaded")),
        ("Facts Loaded", values.get("sp2_facts_loaded")),
        ("Audit Table 2 Run ID", values.get("sp2_run_id")),
        ("Reported At", execution_time),

    ])

    replacements = {
        "{{STATUS_CLASS}}": status_class,
        "{{STATUS_ICON}}": status_icon,
        "{{STATUS_TITLE}}": status_title,
        "{{STATUS_DESCRIPTION}}": status_description,
        "{{PIPELINE_NAME}}": PIPELINE_NAME,
        "{{REGION}}": REGION,
        "{{TRIGGER}}": values.get("trigger") or "Step Functions",
        "{{EXECUTION_TIME}}": execution_time,
        "{{STATUS}}": status,
        "{{DETAIL_ROWS}}": detail_rows,
        "{{ERROR_SECTION}}": build_error_section(values, status),
        "{{NOTIFICATION_TITLE}}": notification_title,
        "{{NOTIFICATION_MESSAGE}}": notification_message,
    }

    for token, value in replacements.items():
        html = html.replace(token, str(value))

    return html


# ─────────────────────────────────────────────────────────────────────────────
# Plain Text Fallback
# ─────────────────────────────────────────────────────────────────────────────

def build_text_fallback(status, values, execution_time):

    text = (
        "SNOWFLAKE PIPELINE NOTIFICATION\n"
        "===============================\n\n"

        f"STATUS: {status}\n\n"

        "EXECUTION DETAILS\n"
        "-----------------\n"

        f"Pipeline        : {PIPELINE_NAME}\n"
        f"Lambda Function : {LAMBDA_FUNCTION_NAME}\n"
        f"Region          : {REGION}\n"
        f"Service         : Amazon SES\n"
        f"Trigger         : {values.get('trigger') or 'Step Functions'}\n"
        f"Reported At     : {execution_time}\n\n"

        "SP1\n"
        "---\n"
        f"Procedure       : SP1_LOAD_STAGING\n"
        f"S3 File         : {values.get('sp1_file_name')}\n"
        f"Query ID        : {values.get('sp1_query_id')}\n"
        f"Status          : {values.get('sp1_status')}\n"
        f"Rows Loaded     : {values.get('sp1_rows_loaded')}\n\n"

        "SP2\n"
        "---\n"
        f"Procedure       : SP2_LOAD_STAR_SCHEMA\n"
        f"Status          : {values.get('sp2_status')}\n"
        f"Rows Read       : {values.get('sp2_rows_read')}\n"
        f"Customers       : {values.get('sp2_customers_loaded')}\n"
        f"Products        : {values.get('sp2_products_loaded')}\n"
        f"Facts           : {values.get('sp2_facts_loaded')}\n"
    )

    if status == "FAILED":

        text += (
            "\n"
            "FAILURE DETAILS\n"
            "---------------\n"

            f"Error Type      : {values.get('Error') or values.get('errorType') or 'PipelineError'}\n"
            f"Error Message   : {values.get('Cause') or values.get('errorMessage') or values.get('sp2_error') or values.get('sp1_error') or values.get('sp1_message')}\n"
        )

    text += (
        "\n--\n"
        "AWS Step Functions | AWS Lambda | Amazon SES | Snowflake\n"
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
        print("SNOWFLAKE PIPELINE -> AMAZON SES NOTIFICATION")
        print("=" * 70)

        status = str(
            event.get(
                "status",
                "SUCCESS"
            )
        ).upper()

        trigger = event.get(
            "trigger",
            "Step Functions"
        )

        # Only SUCCESS or FAILED are allowed
        if status not in [
            "SUCCESS",
            "FAILED"
        ]:

            raise ValueError(
                "status must be either SUCCESS or FAILED"
            )

        # Everything the pipeline produced travels in "detail"
        values = flatten_detail(event.get("detail", {}))

        values["trigger"] = trigger

        # A manual test can send the error fields at the top level
        for field in [
            "errorType",
            "errorMessage",
            "Error",
            "Cause"
        ]:

            if field in event and field not in values:
                values[field] = event[field]

        execution_time = datetime.now(
            timezone.utc
        ).strftime(
            "%Y-%m-%d %H:%M:%S UTC"
        )

        if status == "SUCCESS":

            subject = (
                "Snowflake Pipeline - "
                "Run Completed Successfully"
            )

        else:

            subject = (
                "Snowflake Pipeline - "
                "Run Failed"
            )

        html_body = build_html_email(
            status=status,
            values=values,
            execution_time=execution_time
        )

        text_body = build_text_fallback(
            status=status,
            values=values,
            execution_time=execution_time
        )

        print(f"Status          : {status}")
        print(f"Trigger         : {trigger}")
        print(f"Sender          : {SENDER}")
        print(f"Recipients      : {RECIPIENTS}")
        print(f"Subject         : {subject}")
        print(f"SP1 Query ID    : {values.get('sp1_query_id')}")
        print(f"SP1 Status      : {values.get('sp1_status')}")
        print(f"SP2 Status      : {values.get('sp2_status')}")

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

        print("=" * 70)
        print("EMAIL SENT SUCCESSFULLY")
        print("=" * 70)
        print(f"Notification Status : {status}")
        print(f"SES MessageId       : {message_id}")
        print("=" * 70)

        return {
            "statusCode": 200,
            "body": {
                "status": "SUCCESS",
                "message": "Email sent successfully through Amazon SES",
                "notification_status": status,
                "ses_message_id": message_id,
                "recipients": RECIPIENTS,
                "pipeline_status": "NOTIFIED"
            }
        }

    except Exception as e:

        print("!" * 70)
        print("EMAIL NOTIFICATION FAILED")
        print("!" * 70)
        print(f"Error Type      : {type(e).__name__}")
        print(f"Error Message   : {str(e)}")
        print("!" * 70)

        return {
            "statusCode": 500,
            "body": {
                "status": "FAILED",
                "message": str(e),
                "pipeline_status": "EMAIL_FAILED"
            }
        }
