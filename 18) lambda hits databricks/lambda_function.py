import json
import requests


def lambda_handler(event, context):

    # ─────────────────────────────────────────────
    # 1. Databricks workspace host
    #    No https:// and no trailing slash
    #    Example: "adb-1234567890.4.azuredatabricks.net"
    #             "dbc-12345678-abcd.cloud.databricks.com"
    # ─────────────────────────────────────────────
    databricks_host = "DATABRICKS HOST"

    # ─────────────────────────────────────────────
    # 2. Databricks personal access token (PAT)
    #    Better practice: read it from an environment
    #    variable or Secrets Manager instead of hardcoding.
    # ─────────────────────────────────────────────
    databricks_token = "DATABRICKS TOKEN"

    # ─────────────────────────────────────────────
    # 3. Your Databricks Job ID
    #    Job → Job details → the number after /jobs/
    # ─────────────────────────────────────────────
    job_id = 123456789

    # Databricks Run Now API
    url = f"https://{databricks_host}/api/2.2/jobs/run-now"

    headers = {
        "Authorization": f"Bearer {databricks_token}",
        "Content-Type": "application/json"
    }

    payload = {
        "job_id": job_id
    }

    print("========================================")
    print(f"Triggering Databricks job: {job_id}")
    print(f"URL: {url}")
    print("========================================")

    # Trigger Databricks Job
    response = requests.post(
        url,
        headers=headers,
        json=payload,
        timeout=30
    )

    print("Status Code:", response.status_code)
    print("Response:", response.text)

    # Databricks returns JSON — but on 4xx/5xx the body
    # may not be JSON, so parse it safely
    try:
        body = response.json()
    except json.JSONDecodeError:
        body = {"raw_response": response.text}

    # Return response
    return {
        "statusCode": response.status_code,
        "body": body
    }
