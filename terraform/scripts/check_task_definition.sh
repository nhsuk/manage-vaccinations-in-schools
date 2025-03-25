#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <var-file>"
    exit 1
fi

tf_stdout=$1
# Check task definition is replaced
if [[ $(grep -ce "No changes.*Your infrastructure matches the configuration" "$tf_stdout") -eq 1 ]]; then
  echo "No changes detected, continuing."
  exit 0
fi
if [[ $(grep -cE "aws_ecs_task_definition\.task_definition.*(replaced|created)" "$tf_stdout") -eq 1 ]]; then
  echo "Task definition is being replaced or created"
else
  echo "Task definition is not being replaced, aborting."
  exit 1
fi
if [[ $(grep -cE "aws_s3_object\.appspec_object.*(updated in-place|created)" "$tf_stdout") -eq 1 ]]; then
  echo "S3 bucket object is being replaced or created"
else
  echo "S3 bucket object is not being replaced, aborting."
  exit 1
fi
MODIFICATIONS=$(grep -E "[0-9]+ to add, [0-9]+ to change, [0-9]+ to destroy." "$tf_stdout") || exit 1
ADDITIONS=$(echo "$MODIFICATIONS" | sed -E 's/.*([0-9]+) to add.*/\1/')  || exit 1
CHANGES=$(echo "$MODIFICATIONS" | sed -E 's/.*([0-9]+) to change.*/\1/')  || exit 1
DELETIONS=$(echo "$MODIFICATIONS" | sed -E 's/.*([0-9]+) to destroy.*/\1/') || exit 1
if [[ $DELETIONS -gt $ADDITIONS ]]; then
  echo "More resources are being destroyed than created."
  echo "Other resources than task definition and s3 bucket object are being deleted, aborting."
  exit 1
fi
if [[ $((CHANGES + ADDITIONS)) -gt 2 ]]; then
  echo "More than 2 resources are being changed."
  echo "Other changes than task definition and s3 bucket object are being made, aborting."
  exit 1
fi
echo "Basic checks passed, only task definition and S3 bucket changes observed."
