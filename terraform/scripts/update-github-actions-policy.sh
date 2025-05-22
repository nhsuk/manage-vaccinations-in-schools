#!/usr/bin/env bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <policy-arn> <policy-file>"
    exit 1
fi

POLICY_ARN=$1
POLICY_FILE=$2

# Get existing policy versions
EXISTING_VERSIONS=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query 'Versions[].VersionId' --output text)

# If there are 5 or more versions, delete the oldest one
if [ "$(echo "$EXISTING_VERSIONS" | wc -w)" -ge 5 ]; then
    OLDEST_VERSION=$(echo "$EXISTING_VERSIONS" | awk '{print $NF}')
    echo "Deleting oldest version: $OLDEST_VERSION"
    aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$OLDEST_VERSION"
else
    echo "No need to delete any policy versions."
fi

# Create a new version of the policy
aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document "file://$POLICY_FILE" --set-as-default
