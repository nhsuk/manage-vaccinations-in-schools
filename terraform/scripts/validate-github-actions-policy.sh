#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <policy-arn> <policy-file>"
    exit 1
fi

POLICY_ARN=$1
POLICY_FILE=$2

VERSION_ID=$(aws iam get-policy --policy-arn "$POLICY_ARN" --query 'Policy.DefaultVersionId' --output text)
aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id "$VERSION_ID" --query 'PolicyVersion.Document' --output json > deployed_policy.json

jq -S . deployed_policy.json > deployed_policy_sorted.json
jq -S . "$POLICY_FILE" > github_actions_policy_sorted.json

POLICY_DIFF=$(diff --unified deployed_policy_sorted.json github_actions_policy_sorted.json)
if [ -n "$POLICY_DIFF" ]; then
  echo "Policy mismatch detected: $POLICY_DIFF"
  echo "policy_mismatch=true" >> "$GITHUB_OUTPUT"
else
  echo "No policy mismatch detected"
fi
