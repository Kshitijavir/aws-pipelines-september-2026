# ==============================================================
# PIPELINE : AWS Lambda -> Snowflake Stored Procedure -> External
#            Stage -> Storage Integration -> Amazon S3
#
# FUNCTION : snowflake-s3-export-lambda
# RUNTIME  : Python 3.12
# HANDLER  : lambda_function.lambda_handler
#
# LAYER    : Snowflake Python Connector layer
#            (the standard Lambda runtime does NOT include
#             snowflake.connector)
#
# ROLE     : SnowflakeS3ExportPracticeRole
#            - AWSLambdaBasicExecutionRole  (CloudWatch logs)
#            - AmazonS3FullAccess           (not actually needed
#                                            by this code)
#
# The password below is a PLACEHOLDER.
# Never commit a real Snowflake password to git.
# ==============================================================

import snowflake.connector
import time
from datetime import datetime, timezone


def lambda_handler(event, context):

    start_time = time.time()

    print("=" * 70)
    print("SNOWFLAKE -> S3 EXPORT PIPELINE")
    print("=" * 70)

    print(f"Start Time       : {datetime.now(timezone.utc).isoformat()}")
    print(f"Lambda Request ID: {context.aws_request_id}")
    print(f"Function         : {context.function_name}")
    print()

    conn = None
    cursor = None

    try:

        # ---------------------------------------------------------
        # 1. CONNECT TO SNOWFLAKE
        # ---------------------------------------------------------

        print("[1/4] Connecting to Snowflake...")

        conn = snowflake.connector.connect(
            user="KSHITIJ",
            password="<YOUR_SNOWFLAKE_PASSWORD>",
            account="XLTGLZP-IZC37171",
            warehouse="S3_EXPORT_WH",
            database="SNOWFLAKE_S3_EXPORT_PRACTICE",
            schema="S3_EXPORT_SCHEMA"
        )

        print("      Snowflake connection : SUCCESS")
        print("      Database             : SNOWFLAKE_S3_EXPORT_PRACTICE")
        print("      Schema               : S3_EXPORT_SCHEMA")
        print("      Warehouse            : S3_EXPORT_WH")
        print()

        cursor = conn.cursor()

        # ---------------------------------------------------------
        # 2. CALL THE STORED PROCEDURE
        #    The SP runs COPY INTO @STAFF_S3_EXPORT_STAGE/staff_data.csv
        #    so Snowflake performs the export - Lambda does not.
        # ---------------------------------------------------------

        print("[2/4] Executing Snowflake Stored Procedure...")
        print("      Procedure            : EXPORT_STAFF_TO_S3")

        cursor.execute(
            "CALL EXPORT_STAFF_TO_S3()"
        )

        result = cursor.fetchone()

        print("      Stored Procedure     : SUCCESS")
        print(f"      SP Result            : {result[0]}")
        print()

        # ---------------------------------------------------------
        # 3. VERIFY THE FILE IN S3 THROUGH THE STAGE
        # ---------------------------------------------------------

        print("[3/4] Checking the S3 export location...")

        cursor.execute(
            "LIST @STAFF_S3_EXPORT_STAGE"
        )

        files = cursor.fetchall()

        print("      Stage                : @STAFF_S3_EXPORT_STAGE")

        if files:

            print(f"      Files Found          : {len(files)}")

            for file in files:

                print(f"      File Name            : {file[0]}")
                print(f"      File Size            : {file[1]} bytes")
                print(f"      MD5                  : {file[2]}")

        else:

            print("      WARNING: No files found in the S3 stage.")

        print()

        # ---------------------------------------------------------
        # 4. PIPELINE SUCCESS
        # ---------------------------------------------------------

        execution_time = round(time.time() - start_time, 2)

        print("[4/4] PIPELINE COMPLETED SUCCESSFULLY")
        print()
        print("------------------------------------------------------------------")
        print("EXPORT SUMMARY")
        print("------------------------------------------------------------------")
        print("Source Table              : STAFF_DATA")
        print("Stored Procedure          : EXPORT_STAFF_TO_S3")
        print("Export Stage              : @STAFF_S3_EXPORT_STAGE")
        print("Export Target             : s3://snowflake-s3-export-practice-2026/employee-export/staff_data.csv")
        print("Export Format             : CSV")
        print(f"Files Generated           : {len(files)}")
        print(f"Execution Time            : {execution_time} seconds")
        print("Final Status              : SUCCESS")
        print("------------------------------------------------------------------")
        print("Snowflake exported STAFF_DATA to Amazon S3 successfully.")
        print("=" * 70)

        return {
            "statusCode": 200,
            "body": {
                "status": "SUCCESS",
                "message": "Snowflake SP exported STAFF_DATA to S3",
                "source_table": "STAFF_DATA",
                "stored_procedure": "EXPORT_STAFF_TO_S3",
                "stage": "@STAFF_S3_EXPORT_STAGE",
                "s3_path": "s3://snowflake-s3-export-practice-2026/employee-export/staff_data.csv",
                "files_generated": len(files),
                "execution_time_seconds": execution_time
            }
        }

    except Exception as e:

        execution_time = round(time.time() - start_time, 2)

        print()
        print("!" * 70)
        print("PIPELINE FAILED")
        print("!" * 70)
        print(f"Error Type                : {type(e).__name__}")
        print(f"Error Message             : {str(e)}")
        print(f"Execution Time            : {execution_time} seconds")
        print("Final Status              : FAILED")
        print("!" * 70)

        return {
            "statusCode": 500,
            "body": {
                "status": "FAILED",
                "message": str(e),
                "execution_time_seconds": execution_time
            }
        }

    finally:

        if cursor:
            cursor.close()
            print("Snowflake cursor closed.")

        if conn:
            conn.close()
            print("Snowflake connection closed.")

        print("Lambda execution finished.")
