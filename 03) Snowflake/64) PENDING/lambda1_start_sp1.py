# ─────────────────────────────────────────────────────────────────────────────
# 64) PIPELINE : S3 -> EventBridge -> Step Functions -> Snowflake SP1 -> SP2
#
# JOB      : Lambda 1 of 3
#            Starts SP1 (SP1_LOAD_STAGING) ASYNCHRONOUSLY and returns the
#            Snowflake Query ID to Step Functions. It does NOT wait for SP1.
#
# FUNCTION : snowflake-sp1-start-lambda
# RUNTIME  : Python 3.12
# HANDLER  : lambda1_start_sp1.lambda_handler
#
# LAYER    : Snowflake Python Connector layer
#            (the standard Lambda runtime does NOT include
#             snowflake.connector)
#
# ROLE     : SnowflakeStepFunctionsPracticeRole
#
# The password below is a PLACEHOLDER.
# Never commit a real Snowflake password to git.
# ─────────────────────────────────────────────────────────────────────────────

import re

import snowflake.connector


# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

REGION = "us-east-1"

RAW_BUCKET = "snowflake-step-functions-pipeline-2026"

SNOWFLAKE_USER = "KSHITIJ"
SNOWFLAKE_PASSWORD = "<YOUR_SNOWFLAKE_PASSWORD>"
SNOWFLAKE_ACCOUNT = "XLTGLZP-IZC37171"
SNOWFLAKE_WAREHOUSE = "PIPELINE_WH"
SNOWFLAKE_DATABASE = "SNOWFLAKE_STEP_FUNCTIONS_PIPELINE"
SNOWFLAKE_SCHEMA = "PIPELINE_SCHEMA"

STEP_FUNCTION_NAME = "snowflake-pipeline-state-machine"

# The file name is put inside the CALL statement, so keep it to a plain
# object name: letters, digits, dot, dash, underscore and slash only.
ALLOWED_FILE_NAME = re.compile(r"^[A-Za-z0-9._/-]+$")


# ─────────────────────────────────────────────────────────────────────────────
# Snowflake Connection
#
# The connection is deliberately NOT closed at the end of the handler.
# Closing it logs out the Snowflake session, and a logout cancels a query
# that is still running - which is exactly what SP1 is doing when this
# function returns. Keeping the session open is what lets the asynchronous
# CALL carry on while Step Functions waits.
# ─────────────────────────────────────────────────────────────────────────────

_connection = None


def _session_is_alive(connection):

    cursor = connection.cursor()

    try:
        cursor.execute("SELECT 1")
        return True

    except Exception:
        return False

    finally:
        cursor.close()


def get_connection():
    """
    Returns a Snowflake connection that is reused across invocations.
    """

    global _connection

    if _connection is not None and _session_is_alive(_connection):
        print("      Snowflake connection : REUSED")
        return _connection

    _connection = snowflake.connector.connect(
        user=SNOWFLAKE_USER,
        password=SNOWFLAKE_PASSWORD,
        account=SNOWFLAKE_ACCOUNT,
        warehouse=SNOWFLAKE_WAREHOUSE,
        database=SNOWFLAKE_DATABASE,
        schema=SNOWFLAKE_SCHEMA
    )

    print("      Snowflake connection : NEW")

    return _connection


# ─────────────────────────────────────────────────────────────────────────────
# Read the File Name From the S3 Event
#
# EventBridge sends the S3 event to Step Functions, and Step Functions passes
# it here. The file name lives in detail.object.key.
#
# The stage points at the root of the bucket, so the key itself is the name
# the procedure needs.
# ─────────────────────────────────────────────────────────────────────────────

def resolve_file_name(event):

    detail = event.get("detail", {})

    bucket = detail.get("bucket", {}).get("name")

    s3_key = detail.get("object", {}).get("key")

    # Allows a manual test from the Lambda console
    if not s3_key:
        s3_key = event.get("s3_key") or event.get("file_name")

    if not s3_key:
        raise ValueError(
            "No S3 object key found in the event. Expected "
            "detail.object.key, s3_key or file_name."
        )

    if bucket and bucket != RAW_BUCKET:
        raise ValueError(
            f"Event is for bucket '{bucket}', but this pipeline reads "
            f"'{RAW_BUCKET}'."
        )

    file_name = s3_key

    if not ALLOWED_FILE_NAME.match(file_name):
        raise ValueError(
            f"File name '{file_name}' is not an accepted object name."
        )

    return bucket or RAW_BUCKET, s3_key, file_name


# ─────────────────────────────────────────────────────────────────────────────
# Lambda Handler
# ─────────────────────────────────────────────────────────────────────────────

def lambda_handler(event, context):

    print("=" * 70)
    print("PIPELINE STEP 1 : START SP1 (ASYNCHRONOUS)")
    print("=" * 70)

    print(f"Function         : {context.function_name}")
    print(f"Request ID       : {context.aws_request_id}")
    print(f"State machine    : {STEP_FUNCTION_NAME}")
    print()

    try:

        print("[1/2] Reading the S3 file name from the event...")

        bucket, s3_key, file_name = resolve_file_name(event)

        print(f"      S3 Bucket            : {bucket}")
        print(f"      S3 Key               : {s3_key}")
        print(f"      Stage File Name      : {file_name}")
        print()

        connection = get_connection()

        cursor = connection.cursor()

        try:

            # Lets SP1 finish even if this session is dropped while the
            # query is still running.
            cursor.execute(
                "ALTER SESSION SET ABORT_DETACHED_QUERY = FALSE"
            )

            print("[2/2] Starting SP1 asynchronously...")
            print("      Procedure            : SP1_LOAD_STAGING")

            # execute_async submits the CALL and returns at once,
            # so this function does not sit and wait for SP1.
            handle = cursor.execute_async(
                f"CALL SP1_LOAD_STAGING('{file_name}')"
            )

            query_id = handle.query_id

            print("      Submitted            : YES")
            print(f"      Snowflake Query ID   : {query_id}")
            print()
            print("      SP1 is now running inside Snowflake.")
            print("      Step Functions will wait 3 minutes and then ask")
            print("      Lambda 2 to check this Query ID.")

        finally:
            # The cursor is closed, the connection is not.
            cursor.close()

        return {
            "statusCode": 200,
            "body": {
                "status": "SUBMITTED",
                "message": "SP1 started asynchronously in Snowflake",
                "sp1_query_id": query_id,
                "sp1_file_name": file_name,
                "sp1_status": "STARTED",
                "s3_bucket": bucket,
                "s3_key": s3_key,
                "pipeline_status": "SP1_RUNNING"
            }
        }

    except Exception as e:

        print()
        print("!" * 70)
        print("PIPELINE STEP 1 : FAILED")
        print("!" * 70)
        print(f"Error Type                : {type(e).__name__}")
        print(f"Error Message             : {str(e)}")
        print("!" * 70)

        return {
            "statusCode": 500,
            "body": {
                "status": "FAILED",
                "message": str(e),
                "sp1_status": "FAILURE",
                "sp1_error": str(e),
                "pipeline_status": "FAILED"
            }
        }
