import boto3
import json

# Create Secrets Manager client
secrets_manager = boto3.client("secretsmanager")

# Replace this with your own secret name from Secrets Manager
secret_name = "YOUR SECRET MANAGER NAME"

print("===================================")
print("Glue Job Started")
print("===================================")

try:

    # Fetch secret
    response = secrets_manager.get_secret_value(
        SecretId=secret_name
    )

    # Convert secret string into Python dictionary
    secret = json.loads(response["SecretString"])

    # Get number of keys
    key_count = len(secret.keys())

    print("-----------------------------------")
    print("Secret Manager Pipeline")
    print("-----------------------------------")

    print(f"Secret Name        : {secret_name}")
    print(f"Number of Keys     : {key_count}")

    print("Secret fetched successfully")

    print("-----------------------------------")

except Exception as e:

    print("===================================")
    print("Glue Job Failed")
    print("===================================")

    print("Failed to fetch secret")
    print(f"Error: {str(e)}")

    # Make sure Glue marks the job run as FAILED
    raise

print("===================================")
print("Glue Job Completed Successfully")
print("===================================")
