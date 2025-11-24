#!/usr/bin/env bash

# Script to send Slack notification about migrations running
# Usage: send_slack_notification.sh <slack_webhook_url> <aws_console_url> <message>

slack_webhook_url="$1"
aws_console_url="$2"
message="$3"

if [[ -z "$slack_webhook_url" ]]; then
  echo "Error: Slack webhook URL not provided" >&2
  exit 1
fi

if [[ -z "$aws_console_url" ]]; then
  echo "Error: AWS console URL not provided" >&2
  exit 1
fi

if [[ -z "$message" ]]; then
  echo "Error: Message not provided" >&2
  exit 1
fi

curl -X POST "$slack_webhook_url" \
  -H 'Content-Type: application/json' \
  -d @- <<EOF
{
  "text": "${message} :gear:",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "${message} :gear:"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "<${aws_console_url}|View live logs in AWS Console>"
      }
    }
  ]
}
EOF

if [[ $? -eq 0 ]]; then
  echo "Slack notification sent successfully"
else
  echo "Failed to send Slack notification" >&2
fi
