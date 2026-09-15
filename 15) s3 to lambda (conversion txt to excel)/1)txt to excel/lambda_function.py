import boto3
import csv
import io
import os
from urllib.parse import unquote_plus
from openpyxl import Workbook


s3 = boto3.client("s3")


def lambda_handler(event, context):

    # Get bucket name and file name from S3 event
    record = event["Records"][0]

    bucket_name = record["s3"]["bucket"]["name"]

    raw_key = record["s3"]["object"]["key"]
    input_key = unquote_plus(raw_key)

    print(f"Received file: s3://{bucket_name}/{input_key}")

    # Make sure the uploaded file is a TXT file
    if not input_key.lower().endswith(".txt"):
        print("File is not a TXT file. Skipping.")
        return {
            "statusCode": 200,
            "message": "File skipped because it is not a TXT file."
        }

    # Download TXT file from S3
    response = s3.get_object(
        Bucket=bucket_name,
        Key=input_key
    )

    file_content = response["Body"].read().decode("utf-8")

    print("TXT file downloaded successfully.")

    # Read pipe-delimited TXT data
    reader = csv.reader(
        io.StringIO(file_content),
        delimiter="|"
    )

    rows = list(reader)

    if not rows:
        print("TXT file is empty.")

        return {
            "statusCode": 200,
            "message": "TXT file is empty."
        }

    # Create Excel workbook
    workbook = Workbook()
    worksheet = workbook.active
    worksheet.title = "Data"

    # Write TXT data into Excel
    for row in rows:
        worksheet.append(row)

    print(f"Rows written to Excel: {len(rows)}")

    # Create output filename
    file_name = os.path.basename(input_key)

    base_name = os.path.splitext(file_name)[0]

    output_key = f"output/{base_name}.xlsx"

    # Save Excel workbook in memory
    excel_buffer = io.BytesIO()

    workbook.save(excel_buffer)

    excel_buffer.seek(0)

    # Upload Excel file to S3
    s3.put_object(
        Bucket=bucket_name,
        Key=output_key,
        Body=excel_buffer.getvalue(),
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )

    print(
        f"Excel file created successfully: "
        f"s3://{bucket_name}/{output_key}"
    )

    return {
        "statusCode": 200,
        "input_file": input_key,
        "output_file": output_key,
        "message": "TXT converted to Excel successfully."
    }
