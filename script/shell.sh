#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [--service SERVICE_NAME] [--task-id TASK_ID] [--task-ip TASK_IP] ENV"
    echo "Options:"
    echo "  ENV                       Specify the environment (cluster will be mavis-ENV)"
    echo "  --service SERVICE_NAME    Specify the service name (optional): Ignored if using --task-id or --task-ip"
    echo "  --task-id TASK_ID         Specify the task ID directly (optional)"
    echo "  --task-ip TASK_IP         Specify the task by its IP address (optional): Ignored if using --task-id"
    echo "  --help                    Display this help message"
}

if [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ $# -lt 1 ]; then
    echo "Error: Environment is required"
    usage
    exit 1
fi

region="eu-west-2"
service_name=""
task_id=""
task_ip=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --service)
            service_name="$2"
            shift 2
            ;;
        --task-id)
            task_id="$2"
            shift 2
            ;;
        --task-ip)
            task_ip="$2"
            shift 2
            ;;
        --exit-without-login|-x)
            exit_without_login=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Error: Invalid option $1"
            usage
            exit 1
            ;;
        *)
            env="$1"
            shift
            ;;
    esac
done

if [ -z "$env" ]; then
    echo "Error: Environment cannot be empty"
    usage
    exit 1
fi
if [ "$env" == "production" ]; then
    echo "You are trying to shell into a production container NOT Data-Replication. If you wish to proceed type 'production':"
    read -r confirm
    if [ "$confirm" != "production" ]; then
        echo "Validation failed. Exiting without shelling into production container."
        exit 1
    fi
fi

cluster_name="mavis-$env"

aws sts get-caller-identity &>/dev/null
if [[ $? -ne 0 ]]; then
    if [[ -z "$exit_without_login" ]]; then
        aws sso login
        if [[ $? -ne 0 ]]; then
            echo "Error: AWS CLI SSO login failed. Please log in to your AWS account."
            exit 1
        fi
    else
        echo "Error: AWS SSO login required. Please log in to your AWS account using 'aws sso login'."
        exit 1
    fi
fi

if [ -n "$task_id" ]; then
    task_description=$(aws ecs describe-tasks --region "$region" --cluster "$cluster_name" --task "$task_id")
    if [ -z "$task_description" ] || echo "$task_description" | jq -e '.tasks | length == 0' > /dev/null; then
        echo "Task $task_id not found in cluster $cluster_name"
        exit 1
    fi
    task_status=$(echo "$task_description" | jq -r '.tasks[0].lastStatus')
    if [ "$task_status" != "RUNNING" ]; then
        echo "Task $task_id is not running (status: $task_status)"
        exit 1
    fi
    container_name=$(echo "$task_description" | jq -r '.tasks[0].containers | map(select(.lastStatus == "RUNNING"))[0].name')
    if [ -z "$container_name" ] || [ "$container_name" = "null" ]; then
        echo "No running containers found in task $task_id"
        exit 1
    fi
elif [ -n "$task_ip" ]; then
    if [ -n "$service_name" ]; then
        task_arns=$(aws ecs list-tasks --region "$region" --cluster "$cluster_name" --service-name "$service_name" --desired-status RUNNING | jq -r '.taskArns[]')
    else
        task_arns=$(aws ecs list-tasks --region "$region" --cluster "$cluster_name" --desired-status RUNNING | jq -r '.taskArns[]')
    fi
    if [ -z "$task_arns" ]; then
        echo "No running tasks found in cluster $cluster_name" $([ -n "$service_name" ] && echo "for service $service_name")
        exit 1
    fi
    tasks_description=$(aws ecs describe-tasks --region "$region" --cluster "$cluster_name" --tasks $task_arns)
    if [ -z "$tasks_description" ]; then
        echo "Failed to describe tasks in cluster $cluster_name"
        exit 1
    fi
    task_id=$(echo "$tasks_description" | jq -r '.tasks[] | select(.attachments[]?.details[]? | select(.name=="privateIPv4Address") | .value == "'"$task_ip"'") | .taskArn | split("/") | .[-1]' | head -n1)
    if [ -z "$task_id" ]; then
        echo "No running task found with IP $task_ip in cluster $cluster_name" $([ -n "$service_name" ] && echo "for service $service_name")
        exit 1
    fi
    task_description=$(echo "$tasks_description" | jq '.tasks[] | select(.taskArn | endswith("'"$task_id"'"))')
    container_name=$(echo "$task_description" | jq -r '.containers | map(select(.lastStatus == "RUNNING"))[0].name')
    if [ -z "$container_name" ] || [ "$container_name" = "null" ]; then
        echo "No running containers found in task $task_id"
        exit 1
    fi
else
    if [ -n "$service_name" ]; then
        task_arns=$(aws ecs list-tasks --region "$region" --cluster "$cluster_name" --service-name "$service_name" --desired-status RUNNING | jq -r '.taskArns[]')
    else
        task_arns=$(aws ecs list-tasks --region "$region" --cluster "$cluster_name" --desired-status RUNNING | jq -r '.taskArns[]')
    fi
    if [ -z "$task_arns" ]; then
        echo "No running tasks found in cluster $cluster_name" $([ -n "$service_name" ] && echo "for service $service_name")
        exit 1
    fi
    tasks_description=$(aws ecs describe-tasks --region "$region" --cluster "$cluster_name" --tasks $task_arns)
    if [ -z "$tasks_description" ]; then
        echo "Failed to describe tasks in cluster $cluster_name"
        exit 1
    fi
    selected_task=$(echo "$tasks_description" | jq '.tasks | map(select(.containers | map(.lastStatus == "RUNNING") | any)) | .[0]')
    if [ -z "$selected_task" ] || [ "$selected_task" = "null" ]; then
        echo "No running tasks with running containers found in cluster $cluster_name" $([ -n "$service_name" ] && echo "for service $service_name")
        exit 1
    fi
    task_id=$(echo "$selected_task" | jq -r '.taskArn | split("/") | .[-1]')
    container_name=$(echo "$selected_task" | jq -r '.containers | map(select(.lastStatus == "RUNNING"))[0].name')
fi

echo "Opening an interactive shell in container $container_name of task $task_id"
aws ecs execute-command --region "$region" \
    --cluster "$cluster_name" \
    --task "$task_id" \
    --container "$container_name" \
    --command "/rails/bin/docker-entrypoint /bin/bash" \
    --interactive
