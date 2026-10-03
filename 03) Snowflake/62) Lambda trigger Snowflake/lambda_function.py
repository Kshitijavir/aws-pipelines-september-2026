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
    print("LAMBDA → SNOWFLAKE STUDENT DATA TEST")
    print("=" * 70)

    print(f"Start Time       : {datetime.now(timezone.utc).isoformat()}")
    print(f"Lambda Request ID: {context.aws_request_id}")
    print(f"Function         : {context.function_name}")
    print()

    conn = None
    cursor = None

    try:

        # ========================================================
        # 1. CONNECT TO SNOWFLAKE
        # ========================================================

        print("[1/4] Connecting to Snowflake...")

        conn = snowflake.connector.connect(
            user="JAVIR",
            password="YOUR PASSWORD",
            account="YNWWEWA-UAC06524",
            warehouse="LAMBDA_WH",
            database="LAMBDA_SNOWFLAKE_PRACTICE",
            schema="LAMBDA_SCHEMA"
        )

        print("      Snowflake Connection : SUCCESS")
        print("      User                 : JAVIR")
        print("      Account              : YNWWEWA-UAC06524")
        print("      Database             : LAMBDA_SNOWFLAKE_PRACTICE")
        print("      Schema               : LAMBDA_SCHEMA")
        print("      Warehouse            : LAMBDA_WH")
        print()

        cursor = conn.cursor()

        # ========================================================
        # 2. GET STUDENT RECORD COUNT
        # ========================================================

        print("[2/4] Getting student record count...")

        cursor.execute("""
            SELECT COUNT(*)
            FROM LAMBDA_SNOWFLAKE_PRACTICE.LAMBDA_SCHEMA.STUDENT
        """)

        student_count = cursor.fetchone()[0]

        print(f"      Student Count        : {student_count}")
        print()

        # ========================================================
        # 3. GET STUDENT RECORDS
        # ========================================================

        print("[3/4] Reading STUDENT table...")

        cursor.execute("""
            SELECT
                STUDENT_ID,
                STUDENT_NAME,
                AGE,
                COURSE,
                CITY
            FROM LAMBDA_SNOWFLAKE_PRACTICE.LAMBDA_SCHEMA.STUDENT
            ORDER BY STUDENT_ID
        """)

        students = cursor.fetchall()

        print()
        print("      STUDENT RECORDS")
        print("      " + "-" * 60)

        for student in students:

            print(
                f"      ID={student[0]}, "
                f"Name={student[1]}, "
                f"Age={student[2]}, "
                f"Course={student[3]}, "
                f"City={student[4]}"
            )

        print()

        # ========================================================
        # 4. SUCCESS
        # ========================================================

        execution_time = round(
            time.time() - start_time,
            2
        )

        print("[4/4] PIPELINE COMPLETED SUCCESSFULLY")
        print()

        print("-" * 70)
        print("SUMMARY")
        print("-" * 70)

        print("User                 : JAVIR")
        print("Account              : YNWWEWA-UAC06524")
        print("Database             : LAMBDA_SNOWFLAKE_PRACTICE")
        print("Schema               : LAMBDA_SCHEMA")
        print("Warehouse            : LAMBDA_WH")
        print("Table                : STUDENT")
        print(f"Student Count        : {student_count}")
        print(f"Records Retrieved    : {len(students)}")
        print(f"Execution Time       : {execution_time} seconds")
        print("Final Status         : SUCCESS")

        print("-" * 70)

        return {
            "statusCode": 200,
            "body": {
                "status": "SUCCESS",
                "user": "JAVIR",
                "account": "YNWWEWA-UAC06524",
                "database": "LAMBDA_SNOWFLAKE_PRACTICE",
                "schema": "LAMBDA_SCHEMA",
                "warehouse": "LAMBDA_WH",
                "table": "STUDENT",
                "student_count": student_count,
                "records_retrieved": len(students),
                "execution_time_seconds": execution_time
            }
        }

    except Exception as e:

        execution_time = round(
            time.time() - start_time,
            2
        )

        print()
        print("!" * 70)
        print("PIPELINE FAILED")
        print("!" * 70)

        print(f"Error Type        : {type(e).__name__}")
        print(f"Error Message     : {str(e)}")
        print(f"Execution Time    : {execution_time} seconds")
        print("Final Status      : FAILED")

        print("!" * 70)

        return {
            "statusCode": 500,
            "body": {
                "status": "FAILED",
                "error_type": type(e).__name__,
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
