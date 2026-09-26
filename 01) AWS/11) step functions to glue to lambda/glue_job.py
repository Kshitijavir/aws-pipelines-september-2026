import sys
from awsglue.utils import getResolvedOptions

print("===================================")
print("Glue Job Started")
print("===================================")

# Get status passed from Step Functions
args = getResolvedOptions(sys.argv, ["status"])

status = args["status"].upper()

print(f"Status received from Step Functions: {status}")

try:

    print("Processing started...")

    # ==========================================
    # SUCCESS
    # ==========================================

    if status == "SUCCESS":

        print("Step Functions requested SUCCESS")
        print("Processing completed successfully")

    # ==========================================
    # FAILURE
    # ==========================================

    elif status == "FAILED":

        print("Step Functions requested FAILED")
        print("Intentionally failing Glue job...")

        raise Exception(
            "Glue job failed as requested by Step Functions"
        )

    # ==========================================
    # INVALID STATUS
    # ==========================================

    else:

        raise Exception(
            f"Invalid status received from Step Functions: {status}"
        )

except Exception as e:

    print("===================================")
    print("Glue Job Failed")
    print("===================================")

    print(f"Error: {str(e)}")

    # Make sure Glue marks the job as FAILED
    raise

print("===================================")
print("Glue Job Completed Successfully")
print("===================================")
