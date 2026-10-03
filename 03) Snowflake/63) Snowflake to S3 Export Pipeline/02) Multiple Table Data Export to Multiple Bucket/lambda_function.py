# ==============================================================
# PIPELINE : AWS Lambda -> Snowflake Stored Procedure -> External
#            Stage -> Storage Integration -> Amazon S3
#
# SCENARIO : TWO tables go to TWO buckets
#            STUDENT_DATA -> student bucket
#            COLLEGE_DATA -> college bucket
#
# FUNCTION : snowflake-s3-multi-export-lambda
# RUNTIME  : Python 3.12
# HANDLER  : lambda_function.lambda_handler
#
# LAYER    : Snowflake Python Connector layer
#            (the standard Lambda runtime does NOT include
#             snowflake.connector)
#
# ROLE     : SnowflakeS3MultiExportPracticeRole
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
    print("SNOWFLAKE -> S3 MULTI-TABLE / MULTI-BUCKET EXPORT PIPELINE")
    print("=" * 70)

    print(f"Start Time       : {datetime.now(timezone.utc).isoformat()}")
    print(f"Lambda Request ID: {context.aws_request_id}")
    print(f"Function         : {context.function_name}")
    print()

    conn = None
    cursor = None

    # One entry per bucket. The stored procedure fills each bucket,
    # and then Lambda verifies each bucket through its own stage.
    targets = [
        {
            "source_table": "STUDENT_DATA",
            "stage": "@STUDENT_S3_EXPORT_STAGE",
            "bucket": "snowflake-student-export-2026",
            "file": "student_data.csv",
            "s3_path": "s3://snowflake-student-export-2026/student-export/student_data.csv",
        },
        {
            "source_table": "COLLEGE_DATA",
            "stage": "@COLLEGE_S3_EXPORT_STAGE",
            "bucket": "snowflake-college-export-2026",
            "file": "college_data.csv",
            "s3_path": "s3://snowflake-college-export-2026/college-export/college_data.csv",
        },
    ]

    try:

        # ---------------------------------------------------------
        # 1. CONNECT TO SNOWFLAKE
        # ---------------------------------------------------------

        print("[1/4] Connecting to Snowflake...")

        conn = snowflake.connector.connect(
            user="KSHITIJ",
            password="<YOUR_SNOWFLAKE_PASSWORD>",
            account="XLTGLZP-IZC37171",
            warehouse="S3_MULTI_EXPORT_WH",
            database="SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE",
            schema="S3_MULTI_EXPORT_SCHEMA"
        )

        print("      Snowflake connection : SUCCESS")
        print("      Database             : SNOWFLAKE_S3_MULTI_EXPORT_PRACTICE")
        print("      Schema               : S3_MULTI_EXPORT_SCHEMA")
        print("      Warehouse            : S3_MULTI_EXPORT_WH")
        print()

        cursor = conn.cursor()

        # ---------------------------------------------------------
        # 2. CALL THE STORED PROCEDURE
        #    ONE procedure exports BOTH tables:
        #      COPY INTO @STUDENT_S3_EXPORT_STAGE/student_data.csv
        #      COPY INTO @COLLEGE_S3_EXPORT_STAGE/college_data.csv
        #    so Snowflake performs the export - Lambda does not.
        # ---------------------------------------------------------

        print("[2/4] Executing Snowflake Stored Procedure...")
        print("      Procedure            : EXPORT_STUDENT_AND_COLLEGE_TO_S3")

        cursor.execute(
            "CALL EXPORT_STUDENT_AND_COLLEGE_TO_S3()"
        )

        result = cursor.fetchone()

        print("      Stored Procedure     : SUCCESS")
        print(f"      SP Result            : {result[0]}")
        print()

        # ---------------------------------------------------------
        # 3. VERIFY THE FILES IN BOTH BUCKETS THROUGH THE STAGES
        # ---------------------------------------------------------

        print("[3/4] Checking both S3 export locations...")
        print()

        for target in targets:

            cursor.execute(
                f"LIST {target['stage']}"
            )

            files = cursor.fetchall()

            target["files_found"] = len(files)

            print(f"      Source Table         : {target['source_table']}")
            print(f"      Stage                : {target['stage']}")
            print(f"      Bucket               : {target['bucket']}")

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
        print("Source Tables             : STUDENT_DATA, COLLEGE_DATA")
        print("Stored Procedure          : EXPORT_STUDENT_AND_COLLEGE_TO_S3")
        print("Export Stages             : @STUDENT_S3_EXPORT_STAGE, @COLLEGE_S3_EXPORT_STAGE")
        print("Export Format             : CSV")

        for target in targets:
            print(f"Target Bucket             : {target['bucket']}")
            print(f"  Export Target           : {target['s3_path']}")
            print(f"  Files Generated         : {target['files_found']}")

        print(f"Execution Time            : {execution_time} seconds")
        print("Final Status              : SUCCESS")
        print("------------------------------------------------------------------")
        print("Snowflake exported both tables to their Amazon S3 buckets successfully.")
        print("=" * 70)

        return {
            "statusCode": 200,
            "body": {
                "status": "SUCCESS",
                "message": "Snowflake SP exported STUDENT_DATA and COLLEGE_DATA to their S3 buckets",
                "source_tables": ["STUDENT_DATA", "COLLEGE_DATA"],
                "stored_procedure": "EXPORT_STUDENT_AND_COLLEGE_TO_S3",
                "stages": ["@STUDENT_S3_EXPORT_STAGE", "@COLLEGE_S3_EXPORT_STAGE"],
                "exports": [
                    {
                        "source_table": target["source_table"],
                        "stage": target["stage"],
                        "bucket": target["bucket"],
                        "file": target["file"],
                        "s3_path": target["s3_path"],
                        "files_generated": target["files_found"],
                    }
                    for target in targets
                ],
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
