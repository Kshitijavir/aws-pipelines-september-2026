import boto3
import json

# Create Secrets Manager client
secrets_manager = boto3.client("secretsmanager")


def lambda_handler(event, context):

    # Replace this with your own secret name from Secrets Manager
    secret_name = "YOUR SECRET MANAGER NAME"

    try:

        # Fetch secret
        response = secrets_manager.get_secret_value(
            SecretId=secret_name
        )

        # Convert secret string into Python dictionary
        secret = json.loads(response["SecretString"])

        print("===================================")
        print("Secret Manager Pipeline")
        print("===================================")

        # Print Secret Manager name
        print(f"Secret Name : {secret_name}")

        print("-----------------------------------")
        print("Keys inside Secret:")
        print("-----------------------------------")

        # Print only key names
        for key in secret.keys():
            print(f"- {key}")

        print("-----------------------------------")
        print("Secret fetched successfully")
        print("===================================")

        return {
            "statusCode": 200,
            "message": "Secret fetched successfully"
        }

    except Exception as e:

        print("===================================")
        print("Secret Manager Pipeline Failed")
        print("===================================")

        print("Failed to fetch secret")
        print(f"Error: {str(e)}")

        return {
            "statusCode": 500,
            "message": "Failed to fetch secret"
        }
