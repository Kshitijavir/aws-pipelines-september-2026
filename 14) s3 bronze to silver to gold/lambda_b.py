import os
import urllib.parse
from datetime import datetime
from zoneinfo import ZoneInfo

import boto3

s3 = boto3.client("s3")

# Change this to your real Gold bucket name.
GOLD_BUCKET = "kshitij-gold-bucket"

# The folder in the Gold bucket where success markers are written.
STATUS_FOLDER = "_status"


def lambda_handler(event, context):

    print("=" * 50)
    print("LAMBDA B : SILVER -> GOLD")
    print("=" * 50)

    # This function is NOT called by Step Functions. It is triggered by the
    # Silver bucket's own S3 event, so it receives a plain S3 event.
    detail = event["detail"]

    silver_bucket = detail["bucket"]["name"]

    silver_key = urllib.parse.unquote_plus(
        detail["object"]["key"]
    )

    print(f"Silver Bucket : {silver_bucket}")
    print(f"Silver Key    : {silver_key}")
    print(f"Gold Bucket   : {GOLD_BUCKET}")

    # ---------------------------------------------------------
    # Guard: never treat a success marker as a file to copy
    #
    # The marker itself lives in the Gold bucket, so this should never
    # fire. It is here so a broad trigger on Silver can never send the
    # workflow round in a circle.
    # ---------------------------------------------------------

    if silver_key.startswith(f"{STATUS_FOLDER}/"):
        print(f"Skipping status object: {silver_key}")
        return {"skipped": True, "silver_key": silver_key}

    file_name = os.path.basename(silver_key)

    # ---------------------------------------------------------
    # Build the Year/Month/Day folder from the IST date
    #
    # 2026-09-15  ->  2026/09/15/
    # ---------------------------------------------------------

    ist = ZoneInfo("Asia/Kolkata")

    now = datetime.now(ist)

    date_folder = now.strftime("%Y/%m/%d")

    gold_key = f"{date_folder}/{file_name}"

    # ---------------------------------------------------------
    # Copy Silver -> Gold
    #
    # This is the step that must succeed before any marker is written.
    # If copy_object raises, the marker is never created, so Step
    # Functions keeps polling and eventually reports a timeout rather
    # than a false success.
    # ---------------------------------------------------------

    s3.copy_object(
        CopySource={
            "Bucket": silver_bucket,
            "Key": silver_key
        },
        Bucket=GOLD_BUCKET,
        Key=gold_key
    )

    print(f"Copied        : {silver_key} -> {gold_key}")

    # ---------------------------------------------------------
    # Write the success marker Step Functions is polling for
    #
    # Lambda A named this file identically and handed the name to Step
    # Functions, so both sides agree without ever talking to each other.
    # ---------------------------------------------------------

    status_key = f"{STATUS_FOLDER}/{file_name}_SUCCESS"

    s3.put_object(
        Bucket=GOLD_BUCKET,
        Key=status_key,
        Body=b""
    )

    print(f"Marker Written: {status_key}")
    print("=" * 50)

    return {
        "statusCode": 200,
        "silver_bucket": silver_bucket,
        "silver_key": silver_key,
        "gold_bucket": GOLD_BUCKET,
        "gold_key": gold_key,
        "status_key": status_key
    }
