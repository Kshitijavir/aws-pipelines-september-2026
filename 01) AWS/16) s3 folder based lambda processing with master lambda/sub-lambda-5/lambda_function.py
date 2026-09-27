import boto3


s3 = boto3.client("s3")


def lambda_handler(event, context):

    print("===================================")
    print("Sub Lambda started")
    print("===================================")

    bucket_name = event["bucket_name"]
    folder = event["folder"]
    s3_path = event["s3_path"]
    file_key = event["file_key"]
    file_name = event["file_name"]

    print(f"Bucket: {bucket_name}")
    print(f"Folder: {folder}")
    print(f"S3 Path: {s3_path}")
    print(f"File: {file_name}")
    print(f"File Key: {file_key}")

    # -------------------------------------------------
    # Your actual processing goes here
    # -------------------------------------------------

    print(
        f"Processing file: {file_key}"
    )

    # Example S3 check
    response = s3.list_objects_v2(
        Bucket=bucket_name,
        Prefix=s3_path
    )

    files = response.get(
        "Contents",
        []
    )

    print(
        f"Files found in {s3_path}: "
        f"{len(files)}"
    )

    # -------------------------------------------------
    # If processing fails, raise an exception.
    #
    # Example:
    #
    # raise Exception(
    #     "File validation failed"
    # )
    # -------------------------------------------------

    print(
        "Sub Lambda processing completed successfully"
    )

    return {
        "status": "SUCCESS",
        "message": (
            f"File {file_name} processed "
            f"successfully"
        ),
        "bucket": bucket_name,
        "folder": folder,
        "file": file_name
    }