# AWS Lambda function to send alerts for failed AWS Backup jobs to Slack
#  
#  This function receives messages from an SNS topic and forwards them
#  to a Slack webhook URL configured via environment variable.

import json
import os
import logging

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SLACK_WEBHOOK_URL = os.getenv('SLACK_WEBHOOK_URL')
ENVIRONMENT = os.getenv('ENVIRONMENT')    

def lambda_handler(event, context):
    logger.info("Event: " + str(event))
    timestamp = event['Records'][0]['Sns']['Timestamp']
    job_type = event['Records'][0]['Sns']['MessageAttributes']['EventType']['Value']
    message = event['Records'][0]['Sns']['Message']
    logger.info("Message: " + message)
    logger.info("Message: " + message)

    slack_message = {
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "plain_text",
                    "text": message,
                    "emoji": False
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Timestamp*\n {timestamp}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Job type*\n {job_type}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Environment*\n {ENVIRONMENT}"
                    }
                ]
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "<https://eu-west-2.console.aws.amazon.com/backup/home?region=eu-west-2#/dashboard|View AWS Backup Dashboard>"
                    }
                ]
            }
        ]
    }

    req = Request(SLACK_WEBHOOK_URL, json.dumps(slack_message).encode('utf-8'))
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted: %s", slack_message)
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
