# ─────────────────────────────────────────────────────────────────────────────
# 64) PIPELINE : S3 -> EventBridge -> Step Functions -> Snowflake SP1 -> SP2
#
# JOB      : Lambda 3 of 3
#            Runs SP2 (SP2_LOAD_STAR_SCHEMA) after SP1 has succeeded.
#            SP2 reads STAGING_ORDERS and loads DIM_CUSTOMER, DIM_PRODUCT,
#            FACT_SALES and AUDIT_TABLE_2.
#
#            Unlike SP1, this call WAITS for SP2 to finish, so the result
#            can go straight back to Step Functions.
#
# FUNCTION : snowflake-sp2-run-lambda
# RUNTIME  : Python 3.12
# HANDLER  : lambda3_run_sp2.lambda_handler
#
# LAYER    : Snowflake Python Connector layer
#
# ROLE     : SnowflakeStepFunctionsPracticeRole
#
# TIMEOUT  : Set the Lambda timeout to 5 minutes or more. Lambda 3 waits for
#            SP2, and the default 3 second timeout will not be enough.
#
# The password below is a PLACEHOLDER.
# Never commit a real Snowflake password to git.
# ─────────────────────────────────────────────────────────────────────────────

import time

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

STATUS_SUCCESS = "SUCCESS"
STATUS_FAILURE = "FAILURE"


# ─────────────────────────────────────────────────────────────────────────────
# Read a Value From the Step Functions State
#
# Every function in this pipeline returns both "statusCode" and "body", so a
# value can arrive at the top level or inside "body". This reads either one.
# ─────────────────────────────────────────────────────────────────────────────

def read_state(event, key, default=None):

    if key in event:
        return event[key]

    return event.get("body", {}).get(key, default)


# ─────────────────────────────────────────────────────────────────────────────
# Read What SP2 Wrote in AUDIT_TABLE_2
# ─────────────────────────────────────────────────────────────────────────────

def get_latest_audit_row(cursor):

    cursor.execute(
        """
        SELECT
            RUN_ID,
            ROWS_READ,
            CUSTOMERS_LOADED,
            PRODUCTS_LOADED,
            FACTS_LOADED,
            STATUS,
            MESSAGE,
            STARTED_AT,
            ENDED_AT
        FROM AUDIT_TABLE_2
        ORDER BY RUN_ID DESC
        LIMIT 1
        """
    )

    row = cursor.fetchone()

    if not row:
        return None

    return {
        "run_id": row[0],
        "rows_read": row[1],
        "customers_loaded": row[2],
        "products_loaded": row[3],
        "facts_loaded": row[4],
        "status": row[5],
        "message": row[6],
        "started_at": str(row[7]),
        "ended_at": str(row[8])
    }


# ─────────────────────────────────────────────────────────────────────────────
# Lambda Handler
# ─────────────────────────────────────────────────────────────────────────────

def lambda_handler(event, context):

    start_time = time.time()

    print("=" * 70)
    print("PIPELINE STEP 3 : RUN SP2 (STAGING -> DIMENSIONS + FACT)")
    print("=" * 70)

    print(f"Function         : {context.function_name}")
    print(f"Request ID       : {context.aws_request_id}")
    print(f"SP1 Query ID     : {read_state(event, 'sp1_query_id')}")
    print(f"SP1 Status       : {read_state(event, 'sp1_status')}")
    print(f"SP1 Rows Loaded  : {read_state(event, 'sp1_rows_loaded')}")
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

        print("[1/2] Calling SP2...")
        print("      Procedure            : SP2_LOAD_STAR_SCHEMA")

        # This one waits, because Step Functions needs the result of SP2
        # before it can decide which email to send.
        cursor.execute(
            "CALL SP2_LOAD_STAR_SCHEMA()"
        )

        sp2_result = cursor.fetchone()[0]

        print(f"      SP2 Returned         : {sp2_result}")

        audit_row = get_latest_audit_row(cursor)

        if audit_row:
            print()
            print("      AUDIT_TABLE_2")
            print(f"      Run ID               : {audit_row['run_id']}")
            print(f"      Rows Read            : {audit_row['rows_read']}")
            print(f"      Customers Loaded     : {audit_row['customers_loaded']}")
            print(f"      Products Loaded      : {audit_row['products_loaded']}")
            print(f"      Facts Loaded         : {audit_row['facts_loaded']}")
            print(f"      SP2 Status           : {audit_row['status']}")
            print(f"      SP2 Message          : {audit_row['message']}")

        # SP2 reports its own result, so both the return string and the
        # audit row have to agree before this is a success.
        if (
            str(sp2_result).upper().startswith(STATUS_SUCCESS)
            and audit_row
            and audit_row["status"] == STATUS_SUCCESS
        ):

            sp2_status = STATUS_SUCCESS
            sp2_message = audit_row["message"]

        else:

            sp2_status = STATUS_FAILURE

            if audit_row and audit_row["status"] == STATUS_FAILURE:
                sp2_message = audit_row["message"]
            else:
                sp2_message = str(sp2_result)

        execution_time = round(time.time() - start_time, 2)

        print()
        print("[2/2] RESULT               : SP2 = " + sp2_status)
        print(f"      Reason               : {sp2_message}")
        print(f"      Execution Time       : {execution_time} seconds")
        print("=" * 70)

        return {
            "statusCode": 200,
            "body": {
                "status": sp2_status,
                "sp2_status": sp2_status,
                "sp2_message": sp2_message,
                "sp2_result": sp2_result,
                "sp2_run_id": audit_row["run_id"] if audit_row else None,
                "sp2_rows_read": audit_row["rows_read"] if audit_row else None,
                "sp2_customers_loaded": (
                    audit_row["customers_loaded"] if audit_row else None
                ),
                "sp2_products_loaded": (
                    audit_row["products_loaded"] if audit_row else None
                ),
                "sp2_facts_loaded": (
                    audit_row["facts_loaded"] if audit_row else None
                ),
                "sp2_error": (
                    sp2_message if sp2_status == STATUS_FAILURE else None
                ),
                "execution_time_seconds": execution_time,
                # Carried forward so the email can describe the whole run
                "sp1_query_id": read_state(event, "sp1_query_id"),
                "sp1_file_name": read_state(event, "sp1_file_name"),
                "sp1_rows_loaded": read_state(event, "sp1_rows_loaded"),
                "pipeline_status": f"SP2_{sp2_status}"
            }
        }

    except Exception as e:

        execution_time = round(time.time() - start_time, 2)

        print()
        print("!" * 70)
        print("PIPELINE STEP 3 : FAILED")
        print("!" * 70)
        print(f"Error Type                : {type(e).__name__}")
        print(f"Error Message             : {str(e)}")
        print(f"Execution Time            : {execution_time} seconds")
        print("!" * 70)

        return {
            "statusCode": 500,
            "body": {
                "status": STATUS_FAILURE,
                "sp2_status": STATUS_FAILURE,
                "sp2_error": str(e),
                "execution_time_seconds": execution_time,
                "sp1_query_id": read_state(event, "sp1_query_id"),
                "sp1_file_name": read_state(event, "sp1_file_name"),
                "sp1_rows_loaded": read_state(event, "sp1_rows_loaded"),
                "pipeline_status": "FAILED"
            }
        }

    finally:

        cursor.close()
        connection.close()

        print("Snowflake cursor and connection closed.")
