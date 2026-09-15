import os
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

import boto3
from awsglue.utils import getResolvedOptions


# JOB_NAME is filled in by Glue itself with the job's own name.
# source_bucket and source_key come from Lambda at runtime, so nothing
# about the uploaded file is hardcoded here either.
args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "source_bucket", "source_key"]
)

source_bucket = args["source_bucket"]
source_key = args["source_key"]

# Change this to your real destination bucket.
DESTINATION_BUCKET = "kshitij-bucket-b"

# The folder to create inside Bucket B.
DESTINATION_FOLDER = "New folder"

s3 = boto3.client("s3")


def main():

    print("=" * 50)
    print("GLUE JOB STARTED")
    print("=" * 50)

    print(f"Job Name      : {args['JOB_NAME']}")
    print(f"Source Bucket : {source_bucket}")
    print(f"Source Key    : {source_key}")
    print(f"Destination   : s3://{DESTINATION_BUCKET}/{DESTINATION_FOLDER}/")

    # ---------------------------------------------------------
    # Original file name
    # ---------------------------------------------------------

    original_file_name = os.path.basename(source_key)

    # ---------------------------------------------------------
    # Split the name and the extension.
    # No extension is named anywhere — whatever arrives is carried across.
    # ---------------------------------------------------------

    file_name, file_extension = os.path.splitext(
        original_file_name
    )

    # ---------------------------------------------------------
    # IST timestamp
    # ---------------------------------------------------------

    ist = ZoneInfo("Asia/Kolkata")

    timestamp = datetime.now(ist).strftime(
        "%Y-%m-%d_%H-%M-%S"
    )

    new_file_name = f"{file_name}_{timestamp}{file_extension}"

    # ---------------------------------------------------------
    # Create the folder marker in Bucket B
    # ---------------------------------------------------------

    folder_key = f"{DESTINATION_FOLDER}/"

    s3.put_object(
        Bucket=DESTINATION_BUCKET,
        Key=folder_key,
        Body=b""
    )

    print(f"Folder Created: {folder_key}")

    # ---------------------------------------------------------
    # Copy the file into it
    # ---------------------------------------------------------

    destination_key = f"{DESTINATION_FOLDER}/{new_file_name}"

    s3.copy_object(
        CopySource={
            "Bucket": source_bucket,
            "Key": source_key
        },
        Bucket=DESTINATION_BUCKET,
        Key=destination_key
    )

    print(f"Copied        : {original_file_name} -> {new_file_name}")

    print("=" * 50)
    print("GLUE JOB COMPLETED")
    print("=" * 50)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Anything raised here makes Glue mark the run as FAILED, which is
        # what Step Functions is polling for.
        print()
        print("=" * 50)
        print("GLUE JOB FAILED")
        print("=" * 50)
        print(f"Error : {str(error)}")
        raise
