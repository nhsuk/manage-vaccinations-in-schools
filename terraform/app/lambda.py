import json
import boto3
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        # Initialize AWS SDK clients
        rds_data = boto3.client('rds-data')
        secretsmanager = boto3.client('secretsmanager')

        # Get environment variables
        secret_arn = os.environ['SECRET_ARN']
        cluster_arn = os.environ['CLUSTER_ARN']
        database_name = os.environ['DATABASE_NAME']

        # Retrieve database credentials from Secrets Manager
        secret_response = secretsmanager.get_secret_value(SecretId=secret_arn)
        secret = json.loads(secret_response['SecretString'])

        # Execute a SELECT query using RDS Data API
        response = rds_data.execute_statement(
            resourceArn=cluster_arn,
            secretArn=secret_arn,
            database=database_name,
            sql='SELECT * FROM users LIMIT 10'  # Replace with your query
        )

        logger.info(f"Query response: {response}")
        return {
            'statusCode': 200,
            'body': json.dumps('Query executed successfully')
        }

    except Exception as e:
        logger.error(f"Error executing query: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }
