import boto3
import csv
import io
from urllib.parse import unquote_plus
from openpyxl import Workbook
from botocore.exceptions import ClientError


s3 = boto3.client("s3")


# Expected input files
REQUIRED_FILES = [
    "sales_01.txt",
    "sales_02.txt",
    "sales_03.txt",
    "sales_04.txt",
    "sales_05.txt"
]


def lambda_handler(event, context):

    # ---------------------------------------------------------
    # 1. Get bucket name and control-file key from S3 event
    # ---------------------------------------------------------

    record = event["Records"][0]

    bucket_name = record["s3"]["bucket"]["name"]

    raw_key = record["s3"]["object"]["key"]
    control_file_key = unquote_plus(raw_key)

    print(f"Control file received: s3://{bucket_name}/{control_file_key}")

    # ---------------------------------------------------------
    # 2. Make sure the uploaded file is a .ctl file
    # ---------------------------------------------------------

    if not control_file_key.lower().endswith(".ctl"):
        print("Uploaded file is not a control file. Skipping.")

        return {
            "statusCode": 200,
            "message": "File skipped because it is not a .ctl file."
        }

    # ---------------------------------------------------------
    # 3. Define input folder
    # ---------------------------------------------------------

    input_prefix = "input/"

    print("Checking required input files...")

    # ---------------------------------------------------------
    # 4. Check whether all five TXT files exist
    # ---------------------------------------------------------

    missing_files = []

    for file_name in REQUIRED_FILES:

        file_key = f"{input_prefix}{file_name}"

        try:

            s3.head_object(
                Bucket=bucket_name,
                Key=file_key
            )

            print(f"Found: {file_key}")

        except ClientError as error:

            error_code = error.response["Error"]["Code"]

            if error_code in ("404", "NoSuchKey", "NotFound"):

                print(f"Missing: {file_key}")

                missing_files.append(file_key)

            else:

                # Access denied, throttling, KMS failure, etc.
                # These are NOT "file missing" and must not be silently
                # swallowed into the missing_files list.
                print(f"Error checking {file_key}: {error_code}")

                raise

    # ---------------------------------------------------------
    # 5. Stop if any required file is missing
    # ---------------------------------------------------------

    if missing_files:

        print("Required input files are missing.")

        for file_name in missing_files:
            print(f"Missing file: {file_name}")

        return {
            "statusCode": 400,
            "message": "Required input files are missing.",
            "missing_files": missing_files
        }

    print("All required files are available.")

    # ---------------------------------------------------------
    # 6. Read and merge all TXT files
    # ---------------------------------------------------------

    all_rows = []
    header = None

    for file_name in REQUIRED_FILES:

        file_key = f"{input_prefix}{file_name}"

        print(f"Reading: {file_key}")

        response = s3.get_object(
            Bucket=bucket_name,
            Key=file_key
        )

        file_content = response["Body"].read().decode("utf-8")

        reader = csv.reader(
            io.StringIO(file_content),
            delimiter="|"
        )

        rows = list(reader)

        if not rows:
            print(f"File is empty: {file_key}")
            continue

        # First file provides the Excel header
        if header is None:
            header = rows[0]

        # Add only data rows
        data_rows = rows[1:]

        all_rows.extend(data_rows)

        print(
            f"{file_name}: "
            f"{len(data_rows)} records"
        )

    # ---------------------------------------------------------
    # 7. Validate data
    # ---------------------------------------------------------

    if header is None:
        print("No valid data found.")

        return {
            "statusCode": 400,
            "message": "No valid data found in input files."
        }

    print(
        f"Total records merged: "
        f"{len(all_rows)}"
    )

    # ---------------------------------------------------------
    # 8. Create Excel workbook
    # ---------------------------------------------------------

    workbook = Workbook()

    worksheet = workbook.active

    worksheet.title = "Merged Data"

    # Write header
    worksheet.append(header)

    # Write all records
    for row in all_rows:
        worksheet.append(row)

    # ---------------------------------------------------------
    # 9. Create Excel file in memory
    # ---------------------------------------------------------

    excel_buffer = io.BytesIO()

    workbook.save(excel_buffer)

    excel_buffer.seek(0)

    # ---------------------------------------------------------
    # 10. Define output file
    # ---------------------------------------------------------

    output_key = "output/merged_data.xlsx"

    # ---------------------------------------------------------
    # 11. Upload Excel file to S3
    # ---------------------------------------------------------

    s3.put_object(
        Bucket=bucket_name,
        Key=output_key,
        Body=excel_buffer.getvalue(),
        ContentType=(
            "application/vnd.openxmlformats-officedocument."
            "spreadsheetml.sheet"
        )
    )

    print(
        f"Excel file created successfully: "
        f"s3://{bucket_name}/{output_key}"
    )

    # ---------------------------------------------------------
    # 12. Return response
    # ---------------------------------------------------------

    return {
        "statusCode": 200,
        "input_files": REQUIRED_FILES,
        "total_records": len(all_rows),
        "output_file": output_key,
        "message": "TXT files merged into Excel successfully."
    }
