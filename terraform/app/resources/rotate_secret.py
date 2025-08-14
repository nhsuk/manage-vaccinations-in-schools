import boto3
import logging
import os
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']

    service_client = boto3.client('secretsmanager')

    metadata = service_client.describe_secret(SecretId=arn)
    if not metadata['RotationEnabled']:
        logger.error(f"Secret {arn} is not enabled for rotation")
        raise ValueError(f"Secret {arn} is not enabled for rotation")

    versions = metadata['VersionIdsToStages']
    if token not in versions:
        logger.error(f"Secret version {token} has no stage for rotation of secret {arn}.")
        raise ValueError(f"Secret version {token} has no stage for rotation of secret {arn}.")

    if "AWSCURRENT" in versions[token]:
        logger.info(f"Secret version {token} already set as AWSCURRENT for secret {arn}.")
        return

    if "AWSPENDING" not in versions[token]:
        logger.error(f"Secret version {token} not set as AWSPENDING for rotation of secret {arn}.")
        raise ValueError(f"Secret version {token} not set as AWSPENDING for rotation of secret {arn}.")

    if step == "createSecret":
        create_secret(service_client, arn, token)
    elif step == "setSecret":
        set_secret(service_client, arn, token)
    elif step == "testSecret":
        test_secret(service_client, arn, token)
    elif step == "finishSecret":
        finish_secret(service_client, arn, token)
    else:
        logger.error(f"Invalid step parameter: {step}")
        raise ValueError("Invalid step parameter")

def create_secret(service_client, arn, token):
    try:
        # Check if AWSPENDING secret exists
        service_client.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")
        logger.info(f"createSecret: Secret already exists for {arn} version {token} as AWSPENDING.")
    except service_client.exceptions.ResourceNotFoundException:
        # Generate a 32-character hexadecimal secret (0-9, a-f)
        logger.info(f"createSecret: Generating new 32-character hexadecimal secret for {arn}.")
        new_secret = service_client.get_random_password(
            PasswordLength=32,
            ExcludeUppercase=True,
            ExcludePunctuation=True,
            IncludeSpace=False,
            RequireEachIncludedType=False,
            ExcludeCharacters='ghijklmnopqrstuvwxyz'
        )['RandomPassword']
        service_client.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=new_secret,
            VersionStages=['AWSPENDING']
        )
        logger.info(f"createSecret: Successfully put secret for ARN {arn} and version {token}.")

def set_secret(service_client, arn, token):
    # No external service to update for a generic secret
    pass

def test_secret(service_client, arn, token):
    # No validation required for a generic secret
    pass

def finish_secret(service_client, arn, token):
    metadata = service_client.describe_secret(SecretId=arn)
    current_version = None
    for version, stages in metadata["VersionIdsToStages"].items():
        if "AWSCURRENT" in stages:
            if version == token:
                logger.info(f"finishSecret: Version {version} already marked as AWSCURRENT for {arn}")
                return
            current_version = version
            break
    service_client.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version if current_version else token
    )
    logger.info(f"finishSecret: Successfully set AWSCURRENT stage to version {token} for secret {arn}.")