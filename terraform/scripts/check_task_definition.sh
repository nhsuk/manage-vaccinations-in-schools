#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <var-file>"
    exit 1
fi

valid_resources=(
  "aws_ecs_task_definition\.task_definition" #TODO: Remove after release
  "aws_s3_object\.appspec_object"
  "module\.web_service\.aws_ecs_task_definition"
  "module\.good_job_service\.aws_ecs_task_definition"
)

tf_stdout=$1
if [[ $(grep -ce "No changes.*Your infrastructure matches the configuration" "$tf_stdout") -eq 1 ]]; then
  echo "No changes detected, continuing."
  exit 0
fi

MODIFICATIONS=$(grep -E "[0-9]+ to add, [0-9]+ to change, [0-9]+ to destroy." "$tf_stdout") || exit 1
ADDITIONS=$(echo "$MODIFICATIONS" | sed -E 's/.*([0-9]+) to add.*/\1/')  || exit 1
DELETIONS=$(echo "$MODIFICATIONS" | sed -E 's/.*([0-9]+) to destroy.*/\1/') || exit 1
if [[ $DELETIONS -gt $ADDITIONS ]]; then
  echo "ERROR: More resources are being destroyed than created, run infrastructure deploy first."
  exit 1
else
  echo "CHECK_PASSED: No resources are being destroyed without replacement."
fi

mapfile -t PLANNED_CHANGES < <(grep -E "#.+(replaced|created|updated in-place|destroyed)" "$tf_stdout" || exit 1)

invalid_modifications=()
for change in "${PLANNED_CHANGES[@]}"; do
  valid=0
  for resource in "${valid_resources[@]}"; do
    if [[ "$change" =~ $resource ]]; then
      valid=1
      break
    fi
  done
  if [ $valid -eq 0 ]; then
    invalid_modifications+=("$change")
  fi
done

if [ ! ${#invalid_modifications[@]} -eq 0 ]; then
  echo "FAILED_CHECK: Invalid resources modified"
  for item in "${invalid_modifications[@]}"; do
    echo "  $item"
  done
  echo "Please run an infrastructure deployment."
  exit 1
else
  echo "CHECK_PASSED: All modified resources are expected."
fi

echo "Basic checks passed, if production please evaluate the plan before applying."
