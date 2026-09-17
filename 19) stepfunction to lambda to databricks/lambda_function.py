import os
import json
import urllib.request
import urllib.error
import boto3
from datetime import datetime, timezone


# ============================================================
# DATABRICKS CONFIGURATION
# ============================================================

DATABRICKS_HOST = "YOUR DATABRICKS HOST"

DATABRICKS_TOKEN = "YOUR DATABRICKS TOKEN"

JOB_ID = YOUR DATABRICKS JOB ID


# ============================================================
# SES CONFIGURATION
# ============================================================

REGION = "us-east-1"

SENDER = "no-reply@kshitijaws.site"

RECIPIENTS = [
    "kshitijjavir110@gmail.com",
    "kshitijjavir111@gmail.com",
]


# ============================================================
# FILE PATHS
# ============================================================

BASE_DIR = os.path.dirname(__file__)

HTML_FILE = os.path.join(
    BASE_DIR,
    "email.html"
)

CSS_FILE = os.path.join(
    BASE_DIR,
    "email.css"
)


# ============================================================
# SES CLIENT
# ============================================================

ses = boto3.client(
    "ses",
    region_name=REGION
)


# ============================================================
# LOAD HTML + CSS
# ============================================================

def load_email_template():

    # Read HTML
    with open(
        HTML_FILE,
        "r",
        encoding="utf-8"
    ) as html_file:

        html = html_file.read()


    # Read CSS
    with open(
        CSS_FILE,
        "r",
        encoding="utf-8"
    ) as css_file:

        css = css_file.read()


    # Insert CSS into HTML
    html = html.replace(
        "</head>",
        f"<style>{css}</style></head>"
    )


    return html


# ============================================================
# SEND SUCCESS EMAIL
# ============================================================

def send_success_email(run_id):

    print("=" * 70)
    print("DATABRICKS JOB COMPLETED SUCCESSFULLY")
    print("=" * 70)

    # Load HTML + CSS
    html_body = load_email_template()


    # Current execution time
    execution_time = datetime.now(
        timezone.utc
    ).strftime(
        "%Y-%m-%d %H:%M:%S UTC"
    )


    # Replace placeholders
    html_body = html_body.replace(
        "{{JOB_ID}}",
        str(JOB_ID)
    )

    html_body = html_body.replace(
        "{{RUN_ID}}",
        str(run_id)
    )


    # Send email
    response = ses.send_email(

        Source=SENDER,

        Destination={
            "ToAddresses": RECIPIENTS
        },

        Message={

            "Subject": {
                "Data": "Databricks Job Completed Successfully",
                "Charset": "UTF-8"
            },

            "Body": {

                "Html": {
                    "Data": html_body,
                    "Charset": "UTF-8"
                },

                "Text": {
                    "Data": (
                        "Databricks Job Completed Successfully.\n\n"
                        f"Job ID: {JOB_ID}\n"
                        f"Run ID: {run_id}\n"
                        "Status: SUCCESS\n"
                        f"Execution Time: {execution_time}\n\n"
                        "Notebook 1, Notebook 2 and Notebook 3 "
                        "completed successfully."
                    ),
                    "Charset": "UTF-8"
                }
            }
        }
    )


    message_id = response["MessageId"]


    print("=" * 70)
    print("EMAIL SENT SUCCESSFULLY")
    print("=" * 70)

    print("Job ID     :", JOB_ID)
    print("Run ID     :", run_id)
    print("Sender     :", SENDER)
    print("Recipients :", RECIPIENTS)
    print("Message ID :", message_id)

    print("=" * 70)


    return message_id


# ============================================================
# DATABRICKS API REQUEST
# ============================================================

def databricks_request(
    url,
    method="GET",
    payload=None
):

    headers = {
        "Authorization": f"Bearer {DATABRICKS_TOKEN}",
        "Content-Type": "application/json"
    }


    data = None


    if payload is not None:

        data = json.dumps(
            payload
        ).encode("utf-8")


    request = urllib.request.Request(
        url,
        data=data,
        headers=headers,
        method=method
    )


    try:

        with urllib.request.urlopen(
            request,
            timeout=30
        ) as response:

            response_body = (
                response
                .read()
                .decode("utf-8")
            )


            print(
                "Databricks API Status:",
                response.status
            )


            return json.loads(
                response_body
            )


    except urllib.error.HTTPError as error:

        error_body = (
            error
            .read()
            .decode("utf-8")
        )


        print("=" * 70)
        print("DATABRICKS API ERROR")
        print("=" * 70)

        print(
            "HTTP Status:",
            error.code
        )

        print(
            "Response:",
            error_body
        )

        print("=" * 70)

        raise


    except urllib.error.URLError as error:

        print("=" * 70)
        print("DATABRICKS CONNECTION ERROR")
        print("=" * 70)

        print(
            "Error:",
            str(error)
        )

        print("=" * 70)

        raise


# ============================================================
# START DATABRICKS JOB
# ============================================================

def start_databricks_job():

    print("=" * 70)
    print("STARTING DATABRICKS JOB")
    print("=" * 70)

    print(
        "Job ID:",
        JOB_ID
    )


    url = (
        f"https://{DATABRICKS_HOST}"
        f"/api/2.2/jobs/run-now"
    )


    payload = {
        "job_id": JOB_ID
    }


    response = databricks_request(
        url=url,
        method="POST",
        payload=payload
    )


    run_id = response["run_id"]


    print("=" * 70)
    print("DATABRICKS JOB STARTED")
    print("=" * 70)

    print(
        "Job ID:",
        JOB_ID
    )

    print(
        "Run ID:",
        run_id
    )

    print("=" * 70)


    return run_id


# ============================================================
# CHECK DATABRICKS JOB
# ============================================================

def check_databricks_job(run_id):

    print("=" * 70)
    print("CHECKING DATABRICKS JOB")
    print("=" * 70)

    print(
        "Job ID:",
        JOB_ID
    )

    print(
        "Run ID:",
        run_id
    )


    url = (
        f"https://{DATABRICKS_HOST}"
        f"/api/2.2/jobs/runs/get"
        f"?run_id={run_id}"
    )


    response = databricks_request(
        url=url,
        method="GET"
    )


    state = response.get(
        "state",
        {}
    )


    lifecycle_state = state.get(
        "life_cycle_state"
    )


    result_state = state.get(
        "result_state"
    )


    state_message = state.get(
        "state_message"
    )


    print(
        "Lifecycle State:",
        lifecycle_state
    )

    print(
        "Result State:",
        result_state
    )

    print(
        "State Message:",
        state_message
    )


    # ========================================================
    # JOB STILL RUNNING
    # ========================================================

    if lifecycle_state in [
        "QUEUED",
        "PENDING",
        "RUNNING",
        "BLOCKED",
        "WAITING_FOR_REPAIR",
        "TERMINATING"
    ]:

        print("=" * 70)
        print("DATABRICKS JOB IS STILL RUNNING")
        print("=" * 70)


        return {
            "status": "RUNNING",
            "job_id": JOB_ID,
            "run_id": run_id,
            "lifecycle_state": lifecycle_state,
            "result_state": result_state
        }


    # ========================================================
    # JOB SUCCESS
    # ========================================================

    if (
        lifecycle_state == "TERMINATED"
        and result_state == "SUCCESS"
    ):

        print("=" * 70)
        print("DATABRICKS JOB SUCCESS")
        print("=" * 70)


        # Send email ONLY after successful completion
        send_success_email(run_id)


        return {
            "status": "SUCCESS",
            "job_id": JOB_ID,
            "run_id": run_id,
            "lifecycle_state": lifecycle_state,
            "result_state": result_state
        }


    # ========================================================
    # JOB FAILED
    # ========================================================

    print("=" * 70)
    print("DATABRICKS JOB FAILED")
    print("=" * 70)


    return {
        "status": "FAILED",
        "job_id": JOB_ID,
        "run_id": run_id,
        "lifecycle_state": lifecycle_state,
        "result_state": result_state,
        "state_message": state_message
    }


# ============================================================
# LAMBDA HANDLER
# ============================================================

def lambda_handler(event, context):

    print("=" * 70)
    print("AWS LAMBDA → DATABRICKS JOB")
    print("=" * 70)


    print(
        "Received Event:"
    )

    print(
        json.dumps(event)
    )


    print("=" * 70)


    # ========================================================
    # FIRST INVOCATION
    #
    # Step Functions sends:
    #
    # {}
    #
    # No run_id = START Databricks Job
    # ========================================================

    if "run_id" not in event:

        print(
            "No run_id found."
        )

        print(
            "Starting Databricks Job..."
        )


        run_id = start_databricks_job()


        return {
            "status": "STARTED",
            "job_id": JOB_ID,
            "run_id": run_id
        }


    # ========================================================
    # SUBSEQUENT INVOCATIONS
    #
    # run_id exists = CHECK Databricks Job
    # ========================================================

    run_id = event["run_id"]


    print(
        "run_id found:",
        run_id
    )


    print(
        "Checking Databricks Job..."
    )


    result = check_databricks_job(
        run_id
    )


    print("=" * 70)
    print("LAMBDA RESPONSE")
    print("=" * 70)


    print(
        json.dumps(result)
    )


    print("=" * 70)


    return result
