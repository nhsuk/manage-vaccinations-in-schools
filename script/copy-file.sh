#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [OPTIONS] ENV LOCAL_FILE REMOTE_PATH"
    echo ""
    echo "Copy a local file to an ECS container via S3"
    echo ""
    echo "Arguments:"
    echo "  ENV          Environment (cluster will be mavis-ENV)"
    echo "  LOCAL_FILE   Path to local file to copy"
    echo "  REMOTE_PATH  Destination path in container"
    echo ""
    echo "Options:"
    echo "  --task-id       Task ID"
    echo "  --help          Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 dev ./config.yml /tmp/config.yml"
    echo "  $0 production-data-replication --task-id abc123 ./example.txt example.txt"
}

list_running_tasks() {
    local service_name="$1"
    if [ -n "$service_name" ]; then
        aws ecs list-tasks --region "$region" --cluster "$cluster_name" --service-name "$service_name" --desired-status RUNNING | jq -r '.taskArns[]'
    else
        aws ecs list-tasks --region "$region" --cluster "$cluster_name" --desired-status RUNNING | jq -r '.taskArns[]'
    fi
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

region="eu-west-2"
env=""
service_name=""
task_id=""
local_file=""
remote_path=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --task-id)
            task_id="$2"
            shift 2
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
            if [ -z "$env" ]; then
                env="$1"
            elif [ -z "$local_file" ]; then
                local_file="$1"
            elif [ -z "$remote_path" ]; then
                remote_path="$1"
            else
                echo "Error: Too many arguments"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$env" ] || [ -z "$local_file" ] || [ -z "$remote_path" ]; then
    echo "Error: Missing required arguments (ENV, LOCAL_FILE, REMOTE_PATH)"
    usage
    exit 1
fi

cluster_name="mavis-$env"
if [[ $env == 'production' || $env == 'production-data-replication' ]]; then
    bucket_name="mavis-filetransfer-production"
else
    bucket_name="mavis-filetransfer-development"
fi

if [[ $task_id == "" && ($env == "qa" || $env == "production") ]]; then
    echo "Copying file to ops service task."
    service_name="mavis-$env-ops"
    task_id=$(list_running_tasks "$service_name" | head -n 1 | awk -F'/' '{print $NF}')
elif [[ $task_id == "" && $env == "production-data-replication" ]]; then
    echo "Copying file to data replication task."
    service_name="mavis-production-data-replication"
    task_id=$(list_running_tasks "$service_name" | head -n 1 | awk -F'/' '{print $NF}')
elif [[ $task_id == "" ]]; then
    echo "ERROR Task ID not provided"
    exit 1;
fi

# Generate unique identifier for the S3 object to avoid conflicts
unique_id="temp-$RANDOM"

echo "Uploading to S3 bucket: s3://$bucket_name/$unique_id"
aws s3 cp "$local_file" "s3://$bucket_name/$unique_id"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to upload file to S3"
    exit 1
fi

echo "Downloading from S3 to task $task_id and path: $remote_path "
aws ecs execute-command \
    --region "$region" \
    --cluster "$cluster_name" \
    --task "$task_id" \
    --command "aws s3 cp s3://$bucket_name/$unique_id $remote_path" \
    --interactive

copy_exit_code=$?

echo "Cleaning up S3 object"
aws s3 rm "s3://$bucket_name/$unique_id" --region "$region" &>/dev/null

if [[ $copy_exit_code -eq 0 ]]; then
    echo ""
    echo "File successfully copied to container"
else
    echo ""
    echo "Error: Failed to copy file to container"
    exit 1
fi
