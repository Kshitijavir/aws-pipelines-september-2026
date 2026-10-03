# ─────────────────────────────────────────────────────────────────────────────
# 64) PIPELINE : S3 -> EventBridge -> Step Functions -> Snowflake SP1 -> SP2
#
# JOB      : Lambda 2 of 3
#            Takes the Query ID that Lambda 1 captured and asks Snowflake
#            whether SP1 is still RUNNING, has SUCCEEDED, or has FAILED.
#
#            Step Functions calls this function again after every 3 minute
#            wait, as long as SP1 is still running.
#
# FUNCTION : snowflake-sp1-status-lambda
# RUNTIME  : Python 3.12
# HANDLER  : lambda2_check_sp1.lambda_handler
#
# LAYER    : Snowflake Python Connector layer
#
# ROLE     : SnowflakeStepFunctionsPracticeRole
#
# The password below is a PLACEHOLDER.
# Never commit a real Snowflake password to git.
# ─────────────────────────────────────────────────────────────────────────────

import snowflake.connector


# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

REGION = "us-east-1"

SNOWFLAKE_USER = "KSHITIJ"
SNOWFLAKE_PASSWORD = "<YOUR_SNOWFLAKE_PASSWORD>"
SNOWFLAKE_ACCOUNT = "XLTGLZP-IZC37171"
SNOWFLAKE_WAREHOUSE = "PIPELINE_WH"
SNOWFLAKE_DATABASE = "SNOWFLAKE_STEP_FUNCTIONS_PIPELINE"
SNOWFLAKE_SCHEMA = "PIPELINE_SCHEMA"

# Snowflake reports these three values for a query
STATUS_SUCCESS = "SUCCESS"
STATUS_FAILURE = "FAILURE"
STATUS_RUNNING = "RUNNING"


# ─────────────────────────────────────────────────────────────────────────────
# Ask Snowflake About the Query ID
#
# QUERY_HISTORY_BY_USER returns the queries run by the current user, across
# sessions, and it includes queries that are still running. All four Lambda
# functions connect as the same Snowflake user, so the Query ID that Lambda 1
# captured is visible here.
# ─────────────────────────────────────────────────────────────────────────────

def get_query_status(cursor, query_id):

    cursor.execute(
        """
        SELECT
            QUERY_ID,
            EXECUTION_STATUS,
            ERROR_MESSAGE,
            TOTAL_ELAPSED_TIME
        FROM TABLE(
            INFORMATION_SCHEMA.QUERY_HISTORY_BY_USER(RESULT_LIMIT => 10000)
        )
        WHERE QUERY_ID = %s
        """,
        (query_id,)
    )

    row = cursor.fetchone()

    if not row:
        # The query is not in the history yet, so treat it as still running
        return {
            "query_id": query_id,
            "execution_status": None,
            "error_message": None,
            "elapsed_seconds": None
        }

    return {
        "query_id": row[0],
        "execution_status": row[1],
        "error_message": row[2],
        "elapsed_seconds": row[3]
    }


# ─────────────────────────────────────────────────────────────────────────────
# Read What SP1 Wrote in AUDIT_TABLE_1
#
# The query only tells us that the CALL finished. The audit table tells us
# what SP1 decided: it writes SUCCESS or FAILURE itself, so a run that failed
# inside the procedure is reported here.
# ─────────────────────────────────────────────────────────────────────────────

def get_latest_audit_row(cursor):

    cursor.execute(
        """
        SELECT
            RUN_ID,
            FILE_NAME,
            ROWS_LOADED,
            STATUS,
            MESSAGE,
            STARTED_AT,
            ENDED_AT
        FROM AUDIT_TABLE_1
        ORDER BY RUN_ID DESC
        LIMIT 1
        """
    )

    row = cursor.fetchone()

    if not row:
        return None

    return {
        "run_id": row[0],
        "file_name": row[1],
        "rows_loaded": row[2],
        "status": row[3],
        "message": row[4],
        "started_at": str(row[5]),
        "ended_at": str(row[6])
    }


# ─────────────────────────────────────────────────────────────────────────────
# Work Out the Real SP1 Status
# ─────────────────────────────────────────────────────────────────────────────

def resolve_sp1_status(query_status, audit_row):

    execution_status = query_status["execution_status"]

    # The CALL itself failed, so SP1 never finished
    if execution_status in ("FAIL", "FAILED", "INCIDENT"):

        return STATUS_FAILURE, (
            query_status["error_message"] or "SP1 failed inside Snowflake"
        )

    if execution_status == STATUS_SUCCESS:

        # SP1 ran, but SP1 can still report its own failure
        if audit_row and audit_row["status"] == STATUS_FAILURE:
            return STATUS_FAILURE, audit_row["message"]

        if audit_row and audit_row["status"] == STATUS_SUCCESS:
            return STATUS_SUCCESS, audit_row["message"]

        # The CALL succeeded but wrote no audit row, so do not trust it
        return STATUS_FAILURE, (
            "SP1 finished but wrote no row in AUDIT_TABLE_1"
        )

    return STATUS_RUNNING, "SP1 is still running in Snowflake"


# ─────────────────────────────────────────────────────────────────────────────
# Lambda Handler
# ─────────────────────────────────────────────────────────────────────────────

def lambda_handler(event, context):

    print("=" * 70)
    print("PIPELINE STEP 2 : CHECK SP1 USING THE QUERY ID")
    print("=" * 70)

    print(f"Function         : {context.function_name}")
    print(f"Request ID       : {context.aws_request_id}")
    print()

    query_id = (
        event.get("sp1_query_id")
        or event.get("body", {}).get("sp1_query_id")
    )

    if not query_id:
        raise ValueError(
            "No sp1_query_id in the event. Lambda 2 needs the Query ID that "
            "Lambda 1 returned."
        )

    print(f"[1/2] Query ID       : {query_id}")
    print()

    connection = snowflake.connector.connect(
        user=SNOWFLAKE_USER,
        password=SNOWFLAKE_PASSWORD,
        account=SNOWFLAKE_ACCOUNT,
        warehouse=SNOWFLAKE_WAREHOUSE,
        database=SNOWFLAKE_DATABASE,
        schema=SNOWFLAKE_SCHEMA
    )

    cursor = connection.cursor()

    try:

        query_status = get_query_status(cursor, query_id)

        print("[2/2] Reading Snowflake query history...")
        print(f"      Query ID             : {query_status['query_id']}")
        print(f"      Execution Status     : {query_status['execution_status']}")
        print(f"      Elapsed Time         : {query_status['elapsed_seconds']} ms")

        if query_status["error_message"]:
            print(f"      Error Message        : {query_status['error_message']}")

        audit_row = get_latest_audit_row(cursor)

        if audit_row:
            print()
            print("      AUDIT_TABLE_1")
            print(f"      Run ID               : {audit_row['run_id']}")
            print(f"      File Name            : {audit_row['file_name']}")
            print(f"      Rows Loaded          : {audit_row['rows_loaded']}")
            print(f"      SP1 Status           : {audit_row['status']}")
            print(f"      SP1 Message          : {audit_row['message']}")

        sp1_status, sp1_message = resolve_sp1_status(query_status, audit_row)

        print()
        print(f"      RESULT               : SP1 = {sp1_status}")
        print(f"      Reason               : {sp1_message}")

        if sp1_status == STATUS_RUNNING:
            print()
            print("      Step Functions will wait another 3 minutes and")
            print("      then call this function again with the same Query ID.")

        print("=" * 70)

        return {
            "statusCode": 200,
            "body": {
                "status": "CHECKED",
                "sp1_query_id": query_id,
                "sp1_status": sp1_status,
                "sp1_message": sp1_message,
                "sp1_execution_status": query_status["execution_status"],
                "sp1_elapsed_ms": query_status["elapsed_seconds"],
                "sp1_error": query_status["error_message"],
                "sp1_file_name": (
                    audit_row["file_name"] if audit_row else None
                ),
                "sp1_rows_loaded": (
                    audit_row["rows_loaded"] if audit_row else None
                ),
                "sp1_audit_run_id": (
                    audit_row["run_id"] if audit_row else None
                ),
                "pipeline_status": f"SP1_{sp1_status}"
            }
        }

    finally:

        cursor.close()
        connection.close()

        print("Snowflake cursor and connection closed.")
