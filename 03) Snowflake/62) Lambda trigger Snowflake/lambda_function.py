# This is probably the command you're remembering:

# SELECT
#     CURRENT_USER()       AS USER,
#     CURRENT_ACCOUNT()    AS ACCOUNT,
#     CURRENT_WAREHOUSE()  AS WAREHOUSE,
#     CURRENT_DATABASE()   AS DATABASE,
#     CURRENT_SCHEMA()     AS SCHEMA;

# It will give you something like:

# USER      | ACCOUNT          | WAREHOUSE          | DATABASE                    | SCHEMA
# ----------|------------------|--------------------|-----------------------------|---------------------
# KSHITIJ   | XLTGLZP-IZC37171 | LAMBDA_EXPORT_WH   | LAMBDA_SP_EXPORT_PRACTICE  | LAMBDA_EXPORT_SCHEMA

# Then your Python connection becomes:

# conn = snowflake.connector.connect(
#     user="KSHITIJ",
#     password="YOUR_PASSWORD",
#     account="XLTGLZP-IZC37171",
#     warehouse="LAMBDA_EXPORT_WH",
#     database="LAMBDA_SP_EXPORT_PRACTICE",
#     schema="LAMBDA_EXPORT_SCHEMA"
# )

# Password cannot be retrieved with a Snowflake SQL command—Snowflake won't show your password. You have to provide the password you set for the user.



import snowflake.connector
import time
from datetime import datetime, timezone


def lambda_handler(event, context):

    start_time = time.time()

    print("=" * 70)
    print("SNOWFLAKE DATA EXPORT PIPELINE")
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

        print("[1/5] Connecting to Snowflake...")

        conn = snowflake.connector.connect(
            user="KSHITIJ",
            password="YOUR SNOWFLAKE PASSWORD",
            account="XLTGLZP-IZC37171",
            warehouse="LAMBDA_EXPORT_WH",
            database="LAMBDA_SP_EXPORT_PRACTICE",
            schema="LAMBDA_EXPORT_SCHEMA"
        )

        print("      Snowflake connection: SUCCESS")
        print("      Database             : LAMBDA_SP_EXPORT_PRACTICE")
        print("      Schema               : LAMBDA_EXPORT_SCHEMA")
        print("      Warehouse            : LAMBDA_EXPORT_WH")
        print()

        cursor = conn.cursor()

        # ---------------------------------------------------------
        # 2. CHECK SOURCE DATA
        # ---------------------------------------------------------

        print("[2/5] Checking source table...")

        cursor.execute(
            "SELECT COUNT(*) FROM EMPLOYEE_DATA"
        )

        source_count = cursor.fetchone()[0]

        print("      Source Table         : EMPLOYEE_DATA")
        print(f"      Source Row Count     : {source_count}")
        print()

        # ---------------------------------------------------------
        # 3. CALL STORED PROCEDURE
        # ---------------------------------------------------------

        print("[3/5] Executing Snowflake Stored Procedure...")
        print("      Procedure             : EXPORT_EMPLOYEE_DATA")

        cursor.execute(
            "CALL EXPORT_EMPLOYEE_DATA()"
        )

        result = cursor.fetchone()

        print("      Stored Procedure      : SUCCESS")
        print(f"      SP Result             : {result[0]}")
        print()

        # ---------------------------------------------------------
        # 4. CHECK EXPORTED FILE
        # ---------------------------------------------------------

        print("[4/5] Checking Snowflake Stage...")

        cursor.execute(
            "LIST @EMPLOYEE_EXPORT_STAGE"
        )

        stage_files = cursor.fetchall()

        print("      Stage                 : @EMPLOYEE_EXPORT_STAGE")
        print(f"      Files Exported        : {len(stage_files)}")

        for file in stage_files:

            file_name = file[0]
            file_size = file[1]
            file_md5 = file[2]

            print(f"      File Name             : {file_name}")
            print(f"      File Size             : {file_size} bytes")
            print(f"      MD5                    : {file_md5}")

        print()

        # ---------------------------------------------------------
        # 5. PIPELINE SUCCESS
        # ---------------------------------------------------------

        execution_time = round(time.time() - start_time, 2)

        print("[5/5] PIPELINE COMPLETED SUCCESSFULLY")
        print()
        print("------------------------------------------------------------------")
        print("EXPORT SUMMARY")
        print("------------------------------------------------------------------")
        print(f"Source Table              : EMPLOYEE_DATA")
        print(f"Source Rows               : {source_count}")
        print(f"Stored Procedure          : EXPORT_EMPLOYEE_DATA")
        print(f"Export Stage              : @EMPLOYEE_EXPORT_STAGE")
        print(f"Export Format             : CSV")
        print(f"Files Generated           : {len(stage_files)}")
        print(f"Execution Time            : {execution_time} seconds")
        print(f"Final Status              : SUCCESS")
        print("------------------------------------------------------------------")
        print("Snowflake SP successfully exported data to the stage.")
        print("=" * 70)

        return {
            "statusCode": 200,
            "body": {
                "status": "SUCCESS",
                "message": "Snowflake SP successfully exported data to stage",
                "source_table": "EMPLOYEE_DATA",
                "source_rows": source_count,
                "stored_procedure": "EXPORT_EMPLOYEE_DATA",
                "stage": "@EMPLOYEE_EXPORT_STAGE",
                "files_generated": len(stage_files),
                "execution_time_seconds": execution_time
            }
        }

    except Exception as e:

        execution_time = round(time.time() - start_time, 2)

        print()
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print("PIPELINE FAILED")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print(f"Error Type                : {type(e).__name__}")
        print(f"Error Message             : {str(e)}")
        print(f"Execution Time            : {execution_time} seconds")
        print("Final Status              : FAILED")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

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

        if conn:
            conn.close()

        print()
        print("Snowflake connection closed.")