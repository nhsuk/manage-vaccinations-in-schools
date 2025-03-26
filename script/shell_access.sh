#!/usr/bin/env bash

usage() {
    echo "Usage: $0 --cluster CLUSTER_NAME [--service SERVICE_NAME] [--task_id TASK_ID] [--task_ip TASK_IP]"
    echo "Options:"
    echo "  --cluster CLUSTER_NAME    Specify the ECS cluster name (required)"
    echo "  --service SERVICE_NAME    Specify the service name (optional)"
    echo "  --task_id TASK_ID         Specify the task ID directly (optional)"
    echo "  --task_ip TASK_IP         Specify the task by its IP address (optional)"
    echo "  --help                    Display this help message"
    echo "Note: Parameters can be provided in any order."
}

OPTIONS=$(getopt -o '' --long cluster:,service:,task_id:,task_ip:,help -- "$@")
if ! [ "$OPTIONS" ]; then
    usage
    exit 1
fi

eval set -- "$OPTIONS"

CLUSTER_NAME=""
SERVICE_NAME=""
TASK_ID=""
TASK_IP=""

while true; do
    case "$1" in
        --cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --service)
            SERVICE_NAME="$2"
            shift 2
            ;;
        --task_id)
            TASK_ID="$2"
            shift 2
            ;;
        --task_ip)
            TASK_IP="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [ -z "$CLUSTER_NAME" ]; then
    echo "Error: --cluster is a required parameter"
    usage
    exit 1
fi

REGION="eu-west-2"

if [ -n "$TASK_ID" ]; then
    task_description=$(aws ecs describe-tasks --region "$REGION" --cluster "$CLUSTER_NAME" --task "$TASK_ID")
    if [ -z "$task_description" ] || echo "$task_description" | jq -e '.tasks | length == 0' > /dev/null; then
        echo "Task $TASK_ID not found in cluster $CLUSTER_NAME"
        exit 1
    fi
    task_status=$(echo "$task_description" | jq -r '.tasks[0].lastStatus')
    if [ "$task_status" != "RUNNING" ]; then
        echo "Task $TASK_ID is not running (status: $task_status)"
        exit 1
    fi
    container_name=$(echo "$task_description" | jq -r '.tasks[0].containers | map(select(.lastStatus == "RUNNING"))[0].name')
    if [ -z "$container_name" ] || [ "$container_name" = "null" ]; then
        echo "No running containers found in task $TASK_ID"
        exit 1
    fi
    task_id="$TASK_ID"
elif [ -n "$TASK_IP" ]; then
    if [ -n "$SERVICE_NAME" ]; then
        task_arns=$(aws ecs list-tasks --region "$REGION" --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --desired-status RUNNING | jq -r '.taskArns[]')
    else
        task_arns=$(aws ecs list-tasks --region "$REGION" --cluster "$CLUSTER_NAME" --desired-status RUNNING | jq -r '.taskArns[]')
    fi
    if [ -z "$task_arns" ]; then
        echo "No running tasks found in cluster $CLUSTER_NAME" $([ -n "$SERVICE_NAME" ] && echo "for service $SERVICE_NAME")
        exit 1
    fi
    tasks_description=$(aws ecs describe-tasks --region "$REGION" --cluster "$CLUSTER_NAME" --tasks $task_arns)
    if [ -z "$tasks_description" ]; then
        echo "Failed to describe tasks in cluster $CLUSTER_NAME"
        exit 1
    fi
    task_id=$(echo "$tasks_description" | jq -r '.tasks[] | select(.attachments[]?.details[]? | select(.name=="privateIPv4Address") | .value == "'"$TASK_IP"'") | .taskArn | split("/") | .[-1]' | head -n1)
    if [ -z "$task_id" ]; then
        echo "No running task found with IP $TASK_IP in cluster $CLUSTER_NAME" $([ -n "$SERVICE_NAME" ] && echo "for service $SERVICE_NAME")
        exit 1
    fi
    task_description=$(echo "$tasks_description" | jq '.tasks[] | select(.taskArn | endswith("'"$task_id"'"))')
    container_name=$(echo "$task_description" | jq -r '.containers | map(select(.lastStatus == "RUNNING"))[0].name')
    if [ -z "$container_name" ] || [ "$container_name" = "null" ]; then
        echo "No running containers found in task $task_id"
        exit 1
    fi
else
    if [ -n "$SERVICE_NAME" ]; then
        task_arns=$(aws ecs list-tasks --region "$REGION" --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --desired-status RUNNING | jq -r '.taskArns[]')
    else
        task_arns=$(aws ecs list-tasks --region "$REGION" --cluster "$CLUSTER_NAME" --desired-status RUNNING | jq -r '.taskArns[]')
    fi
    if [ -z "$task_arns" ]; then
        echo "No running tasks found in cluster $CLUSTER_NAME" $([ -n "$SERVICE_NAME" ] && echo "for service $SERVICE_NAME")
        exit 1
    fi
    tasks_description=$(aws ecs describe-tasks --region "$REGION" --cluster "$CLUSTER_NAME" --tasks $task_arns)
    if [ -z "$tasks_description" ]; then
        echo "Failed to describe tasks in cluster $CLUSTER_NAME"
        exit 1
    fi
    selected_task=$(echo "$tasks_description" | jq '.tasks | map(select(.containers | map(.lastStatus == "RUNNING") | any)) | .[0]')
    if [ -z "$selected_task" ] || [ "$selected_task" = "null" ]; then
        echo "No running tasks with running containers found in cluster $CLUSTER_NAME" $([ -n "$SERVICE_NAME" ] && echo "for service $SERVICE_NAME")
        exit 1
    fi
    task_id=$(echo "$selected_task" | jq -r '.taskArn | split("/") | .[-1]')
    container_name=$(echo "$selected_task" | jq -r '.containers | map(select(.lastStatus == "RUNNING"))[0].name')
fi

echo "Opening an interactive shell in container $container_name of task $task_id"
aws ecs execute-command --region "$REGION" \
    --cluster "$CLUSTER_NAME" \
    --task "$task_id" \
    --container "$container_name" \
    --command "/bin/bash" \
    --interactive
