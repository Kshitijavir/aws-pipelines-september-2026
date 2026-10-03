# ==============================================================
# PIPELINE : AWS Lambda -> Snowflake Stored Procedure -> External
#            Stage -> Storage Integration -> Amazon S3
#
# SCENARIO : TWO tables go to ONE bucket, each into its OWN folder
#            STUDENT_RECORDS -> student/  partition
#            COLLEGE_RECORDS -> college/  partition
#
# FUNCTION : snowflake-s3-partition-export-lambda
# RUNTIME  : Python 3.12
# HANDLER  : lambda_function.lambda_handler
#
# LAYER    : Snowflake Python Connector layer
#            (the standard Lambda runtime does NOT include
#             snowflake.connector)
#
# ROLE     : SnowflakeS3PartitionExportPracticeRole
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
    print("SNOWFLAKE -> S3 SINGLE-BUCKET PARTITION EXPORT PIPELINE")
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
            warehouse="S3_PARTITION_EXPORT_WH",
            database="SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE",
            schema="S3_PARTITION_EXPORT_SCHEMA"
        )

        print("      Snowflake connection : SUCCESS")
        print("      Database             : SNOWFLAKE_S3_PARTITION_EXPORT_PRACTICE")
        print("      Schema               : S3_PARTITION_EXPORT_SCHEMA")
        print("      Warehouse            : S3_PARTITION_EXPORT_WH")
        print()

        cursor = conn.cursor()

        # ---------------------------------------------------------
        # 2. CALL THE STORED PROCEDURE
        #    ONE procedure exports BOTH tables into the SAME bucket,
        #    each one into its own folder:
        #      COPY INTO @PARTITION_S3_EXPORT_STAGE/student/student_records.csv
        #      COPY INTO @PARTITION_S3_EXPORT_STAGE/college/college_records.csv
        #    so Snowflake performs the export - Lambda does not.
        # ---------------------------------------------------------

        print("[2/4] Executing Snowflake Stored Procedure...")
        print("      Procedure            : EXPORT_STUDENT_AND_COLLEGE_PARTITIONS_TO_S3")

        cursor.execute(
            "CALL EXPORT_STUDENT_AND_COLLEGE_PARTITIONS_TO_S3()"
        )

        result = cursor.fetchone()

        print("      Stored Procedure     : SUCCESS")
        print(f"      SP Result            : {result[0]}")
        print()

        # ---------------------------------------------------------
        # 3. VERIFY EACH PARTITION INSIDE THE SAME BUCKET
        #    The stage is one, but we list one folder at a time.
        # ---------------------------------------------------------

        print("[3/4] Checking both partitions in the S3 bucket...")

        cursor.execute(
            "LIST @PARTITION_S3_EXPORT_STAGE/student/"
        )

        student_files = cursor.fetchall()

        print("      Stage Path           : @PARTITION_S3_EXPORT_STAGE/student/")

        if student_files:

            print(f"      Files Found          : {len(student_files)}")

            for file in student_files:

                print(f"      File Name            : {file[0]}")
                print(f"      File Size            : {file[1]} bytes")
                print(f"      MD5                  : {file[2]}")

        else:

            print("      WARNING: No files found in the student partition.")

        print()

        cursor.execute(
            "LIST @PARTITION_S3_EXPORT_STAGE/college/"
        )

        college_files = cursor.fetchall()

        print("      Stage Path           : @PARTITION_S3_EXPORT_STAGE/college/")

        if college_files:

            print(f"      Files Found          : {len(college_files)}")

            for file in college_files:

                print(f"      File Name            : {file[0]}")
                print(f"      File Size            : {file[1]} bytes")
                print(f"      MD5                  : {file[2]}")

        else:

            print("      WARNING: No files found in the college partition.")

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
        print("Source Tables             : STUDENT_RECORDS, COLLEGE_RECORDS")
        print("Stored Procedure          : EXPORT_STUDENT_AND_COLLEGE_PARTITIONS_TO_S3")
        print("Export Stage              : @PARTITION_S3_EXPORT_STAGE")
        print("Target Bucket             : snowflake-partition-export-2026")
        print("Export Format             : CSV")
        print("Export Target 1           : s3://snowflake-partition-export-2026/student/student_records.csv")
        print(f"Files Generated 1         : {len(student_files)}")
        print("Export Target 2           : s3://snowflake-partition-export-2026/college/college_records.csv")
        print(f"Files Generated 2         : {len(college_files)}")
        print(f"Execution Time            : {execution_time} seconds")
        print("Final Status              : SUCCESS")
        print("------------------------------------------------------------------")
        print("Snowflake exported both tables into their S3 partitions successfully.")
        print("=" * 70)

        return {
            "statusCode": 200,
            "body": {
                "status": "SUCCESS",
                "message": "Snowflake SP exported STUDENT_RECORDS and COLLEGE_RECORDS into their S3 partitions",
                "source_tables": ["STUDENT_RECORDS", "COLLEGE_RECORDS"],
                "stored_procedure": "EXPORT_STUDENT_AND_COLLEGE_PARTITIONS_TO_S3",
                "stage": "@PARTITION_S3_EXPORT_STAGE",
                "bucket": "snowflake-partition-export-2026",
                "stage_paths": [
                    "@PARTITION_S3_EXPORT_STAGE/student/",
                    "@PARTITION_S3_EXPORT_STAGE/college/"
                ],
                "s3_paths": [
                    "s3://snowflake-partition-export-2026/student/student_records.csv",
                    "s3://snowflake-partition-export-2026/college/college_records.csv"
                ],
                "files_generated": [len(student_files), len(college_files)],
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
