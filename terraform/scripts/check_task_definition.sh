#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <var-file>"
    exit 1
fi

tfstdout=$1
# Check task definition is replaced
if [[ $(grep -ce "aws_ecs_task_definition\.task_definition.*replaced" "$tfstdout") -eq 1 ]]; then
  echo "Task definition is being replaced"
else
  echo "Task definition is not being replaced, aborting."
  exit 1
fi
if [[ $(grep -ce "aws_s3_object\.appspec_object.*updated in-place" "$tfstdout") -eq 1 ]]; then
  echo "S3 bucket object is being replaced"
else
  echo "S3 bucket object is not being replaced, aborting."
  exit 1
fi
if [[ $(grep -c "1 to add, 1 to change, 1 to destroy." "$tfstdout") -eq 1 ]]; then
  echo "Only 1 change and 1 replace detected"
else
  echo "Other changes than task definition and s3 bucket object are being made"
  exit 1
fi
echo "Basic checks passed, only task definition and S3 bucket changes observed."
return 0
