import boto3
import json

from pyspark.context import SparkContext
from awsglue.context import GlueContext


sc = SparkContext()
glueContext = GlueContext(sc)

logger = glueContext.get_logger()


secrets_manager = boto3.client("secretsmanager")

secret_name = "YOUR SECRET MANAGER NAME"


print("===================================")
print("Glue Job Started")
print("===================================")

logger.info("===================================")
logger.info("Glue Job Started")
logger.info("===================================")


try:

    print("-----------------------------------")
    print("Fetching secret from Secrets Manager")
    print("-----------------------------------")

    logger.info("-----------------------------------")
    logger.info("Fetching secret from Secrets Manager")
    logger.info("-----------------------------------")


    response = secrets_manager.get_secret_value(
        SecretId=secret_name
    )


    secret = json.loads(
        response["SecretString"]
    )


    print("-----------------------------------")
    print("Secret Manager Pipeline")
    print("-----------------------------------")

    print(f"Secret Name : {secret_name}")

    logger.info("-----------------------------------")
    logger.info("Secret Manager Pipeline")
    logger.info("-----------------------------------")

    logger.info(f"Secret Name : {secret_name}")


    print("-----------------------------------")
    print("Keys inside Secret:")
    print("-----------------------------------")

    logger.info("-----------------------------------")
    logger.info("Keys inside Secret:")
    logger.info("-----------------------------------")


    for key in secret.keys():

        print(f"- {key}")
        logger.info(f"- {key}")


    print("-----------------------------------")
    print("Secret fetched successfully")
    print("-----------------------------------")

    logger.info("-----------------------------------")
    logger.info("Secret fetched successfully")
    logger.info("-----------------------------------")


except Exception as e:

    print("===================================")
    print("Glue Job Failed")
    print("===================================")

    print("Failed to fetch secret")
    print(f"Error: {str(e)}")


    logger.error("===================================")
    logger.error("Glue Job Failed")
    logger.error("===================================")

    logger.error("Failed to fetch secret")
    logger.error(f"Error: {str(e)}")


    raise


print("===================================")
print("Glue Job Completed Successfully")
print("===================================")

logger.info("===================================")
logger.info("Glue Job Completed Successfully")
logger.info("===================================")
