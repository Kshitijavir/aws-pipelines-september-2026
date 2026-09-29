import boto3
import json

# Create Secrets Manager client
secrets_manager = boto3.client("secretsmanager")

def lambda_handler(event, context):

    secret_name = "practice/lambda/database-secret"

    try:
        # Fetch secret
        response = secrets_manager.get_secret_value(
            SecretId=secret_name
        )

        # Convert secret string into Python dictionary
        secret = json.loads(response["SecretString"])

        # Get number of keys
        key_count = len(secret.keys())

        print("===================================")
        print("Secret Manager Pipeline")
        print("===================================")

        print(f"Secret Name        : {secret_name}")
        print(f"Number of Keys     : {key_count}")

        print("Secret fetched successfully")

        print("===================================")

        return {
            "statusCode": 200,
            "message": "Secret fetched successfully"
        }

    except Exception as e:

        print("Failed to fetch secret")
        print(f"Error: {str(e)}")

        return {
            "statusCode": 500,
            "message": "Failed to fetch secret"
        }
