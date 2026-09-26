import boto3
import csv
import io
from urllib.parse import unquote_plus
from openpyxl import Workbook
from botocore.exceptions import ClientError


s3 = boto3.client("s3")


def lambda_handler(event, context):

    # ---------------------------------------------------------
    # 1. Get bucket name and uploaded file key
    # ---------------------------------------------------------

    record = event["Records"][0]

    bucket_name = record["s3"]["bucket"]["name"]

    raw_key = record["s3"]["object"]["key"]

    uploaded_file_key = unquote_plus(raw_key)

    print(
        f"File received: "
        f"s3://{bucket_name}/{uploaded_file_key}"
    )

    # ---------------------------------------------------------
    # 2. Make sure uploaded file is a .ctl file
    # ---------------------------------------------------------

    if not uploaded_file_key.lower().endswith(".ctl"):

        print("Uploaded file is not a control file. Skipping.")

        return {
            "statusCode": 200,
            "message": "File skipped because it is not a .ctl file."
        }

    # ---------------------------------------------------------
    # 3. Define input folder
    # ---------------------------------------------------------

    input_prefix = "input/"

    print(
        f"Searching for TXT files in "
        f"s3://{bucket_name}/{input_prefix}"
    )

    # ---------------------------------------------------------
    # 4. Find all TXT files dynamically
    # ---------------------------------------------------------

    txt_files = []

    continuation_token = None

    while True:

        if continuation_token:

            response = s3.list_objects_v2(
                Bucket=bucket_name,
                Prefix=input_prefix,
                ContinuationToken=continuation_token
            )

        else:

            response = s3.list_objects_v2(
                Bucket=bucket_name,
                Prefix=input_prefix
            )

        for obj in response.get("Contents", []):

            file_key = obj["Key"]

            if file_key.endswith("/"):
                continue

            if file_key.lower().endswith(".txt"):

                txt_files.append(file_key)

                print(f"Found TXT file: {file_key}")

        if response.get("IsTruncated"):

            continuation_token = response[
                "NextContinuationToken"
            ]

        else:

            break

    # ---------------------------------------------------------
    # 5. Check whether TXT files exist
    # ---------------------------------------------------------

    if not txt_files:

        print("No TXT files found.")

        return {
            "statusCode": 400,
            "message": "No TXT files found in input folder."
        }

    print(
        f"Total TXT files found: {len(txt_files)}"
    )

    # ---------------------------------------------------------
    # 6. Read and merge all TXT files
    # ---------------------------------------------------------

    all_rows = []

    header = None

    for file_key in txt_files:

        print(f"Reading: {file_key}")

        try:

            response = s3.get_object(
                Bucket=bucket_name,
                Key=file_key
            )

            file_content = (
                response["Body"]
                .read()
                .decode("utf-8")
            )

        except ClientError as error:

            print(
                f"Error reading {file_key}: {error}"
            )

            raise

        reader = csv.reader(
            io.StringIO(file_content),
            delimiter="|"
        )

        rows = list(reader)

        if not rows:

            print(f"File is empty: {file_key}")

            continue

        # First TXT file provides the header
        if header is None:

            header = rows[0]

        # Add data rows only
        data_rows = rows[1:]

        all_rows.extend(data_rows)

        print(
            f"{file_key}: "
            f"{len(data_rows)} records"
        )

    # ---------------------------------------------------------
    # 7. Validate data
    # ---------------------------------------------------------

    if header is None:

        print("No valid data found.")

        return {
            "statusCode": 400,
            "message": "No valid data found in TXT files."
        }

    print(
        f"Total records merged: {len(all_rows)}"
    )

    # ---------------------------------------------------------
    # 8. Create Excel workbook
    # ---------------------------------------------------------

    workbook = Workbook()

    worksheet = workbook.active

    worksheet.title = "Merged Data"

    # Write header
    worksheet.append(header)

    # Write data
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
        "control_file": uploaded_file_key,
        "txt_files": txt_files,
        "total_txt_files": len(txt_files),
        "total_records": len(all_rows),
        "output_file": output_key,
        "message": "TXT files merged into Excel successfully."
    }
