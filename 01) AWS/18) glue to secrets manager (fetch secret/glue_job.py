import boto3
import json
import logging

# Create a logger so every line carries the time and the level
logger = logging.getLogger("secret-manager-pipeline")
logger.setLevel(logging.INFO)

# Create Secrets Manager client
secrets_manager = boto3.client("secretsmanager")

# Replace this with your own secret name from Secrets Manager
secret_name = "YOUR SECRET MANAGER NAME"

logger.info("===================================")
logger.info("Glue Job Started")
logger.info("===================================")

try:

    # Fetch secret
    response = secrets_manager.get_secret_value(
        SecretId=secret_name
    )

    # Convert secret string into Python dictionary
    secret = json.loads(response["SecretString"])

    # Get number of keys
    key_count = len(secret.keys())

    logger.info("-----------------------------------")
    logger.info("Secret Manager Pipeline")
    logger.info("-----------------------------------")

    logger.info(f"Secret Name        : {secret_name}")
    logger.info(f"Number of Keys     : {key_count}")

    logger.info("Secret fetched successfully")

    logger.info("-----------------------------------")

except Exception as e:

    logger.error("===================================")
    logger.error("Glue Job Failed")
    logger.error("===================================")

    logger.error("Failed to fetch secret")
    logger.error(f"Error: {str(e)}")

    # Make sure Glue marks the job run as FAILED
    raise

logger.info("===================================")
logger.info("Glue Job Completed Successfully")
logger.info("===================================")
