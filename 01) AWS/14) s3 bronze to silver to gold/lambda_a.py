import os
import urllib.parse
from datetime import datetime
from zoneinfo import ZoneInfo

import boto3

s3 = boto3.client("s3")

# Change this to your real Silver bucket name.
SILVER_BUCKET = "kshitij-silver-bucket"

# The folder in the Gold bucket where success markers are written.
STATUS_FOLDER = "_status"


def lambda_handler(event, context):

    print("=" * 50)
    print("LAMBDA A : BRONZE -> SILVER")
    print("=" * 50)

    # Step Functions forwards the whole EventBridge event, so the S3 details
    # are under "detail" exactly as S3 produced them.
    detail = event["detail"]

    bronze_bucket = detail["bucket"]["name"]

    bronze_key = urllib.parse.unquote_plus(
        detail["object"]["key"]
    )

    original_file_name = os.path.basename(bronze_key)

    print(f"Bronze Bucket : {bronze_bucket}")
    print(f"Bronze Key    : {bronze_key}")
    print(f"Silver Bucket : {SILVER_BUCKET}")

    # ---------------------------------------------------------
    # Add an IST timestamp to the file name
    #
    # No extension is named anywhere — whatever arrives is carried across.
    # ---------------------------------------------------------

    ist = ZoneInfo("Asia/Kolkata")

    timestamp = datetime.now(ist).strftime(
        "%Y-%m-%d_%H-%M-%S"
    )

    file_name, file_extension = os.path.splitext(
        original_file_name
    )

    silver_key = f"{file_name}_{timestamp}{file_extension}"

    # ---------------------------------------------------------
    # Copy Bronze -> Silver
    # ---------------------------------------------------------

    s3.copy_object(
        CopySource={
            "Bucket": bronze_bucket,
            "Key": bronze_key
        },
        Bucket=SILVER_BUCKET,
        Key=silver_key
    )

    print(f"Copied        : {original_file_name} -> {silver_key}")

    # ---------------------------------------------------------
    # Work out the success marker Lambda B will write
    #
    # Because the timestamp above is part of the name, this marker is
    # unique to this run. That matters: if the marker were named after the
    # original file only, a second upload of the same file would find the
    # marker left behind by the first run and report success instantly —
    # before Lambda B had done anything.
    # ---------------------------------------------------------

    status_key = f"{STATUS_FOLDER}/{silver_key}_SUCCESS"

    print(f"Waiting For   : {status_key}")
    print("=" * 50)

    # Step Functions reads silver_key and status_key out of this return
    # value: silver_key proves nothing yet, status_key is what it polls for.
    return {
        "statusCode": 200,
        "bronze_bucket": bronze_bucket,
        "bronze_key": bronze_key,
        "silver_bucket": SILVER_BUCKET,
        "silver_key": silver_key,
        "status_key": status_key
    }
