#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ECS cluster name>"
    exit 1
fi

REGION=eu-west-2
CLUSTER_NAME=$1

task_ids=$(aws ecs --region $REGION list-tasks --cluster "$CLUSTER_NAME" | jq -r '.taskArns[] | split("/") | .[-1]')
if [ -z "$task_ids" ] || [ "$task_ids" = "null" ]; then
    echo "No tasks found in cluster $CLUSTER_NAME"
    exit 1
fi

found_container=false
for task in $task_ids; do
  container_name=$(aws ecs describe-tasks --region $REGION --cluster "$CLUSTER_NAME" --task "$task" | \
                  jq -r '.tasks  | map(select(.lastStatus == "RUNNING"))[0] | .containers | map(select(.lastStatus == "RUNNING"))[0] | .name')
  if [ -n "$container_name" ] || [ "$container_name" != "null" ]; then
      echo "Task $task has a running container"
      task_id=$task
      found_container=true
      break
  fi
done

if [ "$found_container" = "false" ]; then
  echo "No running containers found in tasks" "${task_ids[@]}"
  exit 1
fi


echo "Opening an interactive shell in container $container_name of task $task_id"

aws ecs execute-command --region $REGION \
        --cluster "$1" \
        --task "$task_id" \
        --container "$container_name" \
        --command "/bin/bash" --interactive
