region="eu-west-2"
env=${args[environment]}
local_file=${args[local-file]}
remote_path=${args[remote-path]}
task_id=${args[--task-id]}
task_ip=${args[--task-ip]}

confirm_production

authenticate_user

set_service_name
if [[ "$service_type" != "ops" ]]; then
    echo "This command requires an ops service but one isn't available in $env env"
    exit 1
fi
   
echo "Using service: $service_name"

set_cluster_name
set_task_info

echo "Task ID: $task_id"
echo "Container: $container_name"

if [[ $env == 'production' || $env == 'production-data-replication' ]]; then
    bucket_name="mavis-filetransfer-production"
else
    bucket_name="mavis-filetransfer-development"
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
echo container_name: $container_name
echo task_id: $task_id
aws ecs execute-command \
    --region "$region" \
    --cluster "$cluster_name" \
    --task "$task_id" \
    --container "$container_name" \
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
