import boto3
import os
import urllib.parse
from datetime import datetime
from zoneinfo import ZoneInfo


s3 = boto3.client("s3")

DESTINATION_BUCKET = "kshitij-destination-bucket"
DESTINATION_FOLDER = "kshitij"


def lambda_handler(event, context):

    print("=" * 50)
    print("S3 FILE COPY STARTED")
    print("=" * 50)

    try:
        # ---------------------------------------------------------
        # Read S3 event information
        # ---------------------------------------------------------

        detail = event["detail"]

        source_bucket = detail["bucket"]["name"]
        source_key = urllib.parse.unquote_plus(
            detail["object"]["key"]
        )

        file_size = detail["object"].get("size", 0)

        # ---------------------------------------------------------
        # Get original file name
        # ---------------------------------------------------------

        original_file_name = os.path.basename(source_key)

        # ---------------------------------------------------------
        # Convert file size to KB
        # ---------------------------------------------------------

        file_size_kb = file_size / 1024

        # ---------------------------------------------------------
        # Print source information
        # ---------------------------------------------------------

        print()
        print(f"Source Bucket : {source_bucket}")
        print(f"File Name     : {original_file_name}")
        print(f"File Size     : {file_size_kb:.2f} KB")

        # ---------------------------------------------------------
        # Create kshitij folder
        # ---------------------------------------------------------

        folder_key = f"{DESTINATION_FOLDER}/"

        s3.put_object(
            Bucket=DESTINATION_BUCKET,
            Key=folder_key,
            Body=b""
        )

        print()
        print(f"Folder        : {DESTINATION_FOLDER}/")

        # ---------------------------------------------------------
        # Create IST timestamp
        # ---------------------------------------------------------

        ist = ZoneInfo("Asia/Kolkata")

        timestamp = datetime.now(ist).strftime(
            "%Y-%m-%d_%H-%M-%S"
        )

        # ---------------------------------------------------------
        # Separate filename and extension
        # ---------------------------------------------------------

        file_name, file_extension = os.path.splitext(
            original_file_name
        )

        # ---------------------------------------------------------
        # Create new filename
        # ---------------------------------------------------------

        new_file_name = (
            f"{file_name}_{timestamp}{file_extension}"
        )

        # ---------------------------------------------------------
        # Destination key
        # ---------------------------------------------------------

        destination_key = (
            f"{DESTINATION_FOLDER}/{new_file_name}"
        )

        # ---------------------------------------------------------
        # Copy file
        # ---------------------------------------------------------

        s3.copy_object(
            CopySource={
                "Bucket": source_bucket,
                "Key": source_key
            },
            Bucket=DESTINATION_BUCKET,
            Key=destination_key
        )

        # ---------------------------------------------------------
        # Print destination information
        # ---------------------------------------------------------

        print()
        print(f"Destination Bucket : {DESTINATION_BUCKET}")
        print(f"File Name          : {new_file_name}")
        print(f"File Size          : {file_size_kb:.2f} KB")

        print()
        print("=" * 50)
        print("S3 FILE COPY COMPLETED")
        print("=" * 50)

        return {
            "statusCode": 200,
            "source_bucket": source_bucket,
            "source_file": original_file_name,
            "file_size": file_size,
            "destination_bucket": DESTINATION_BUCKET,
            "destination_file": new_file_name
        }

    except Exception as error:

        print()
        print("=" * 50)
        print("S3 FILE COPY FAILED")
        print("=" * 50)

        print(f"Error : {str(error)}")

        raise
