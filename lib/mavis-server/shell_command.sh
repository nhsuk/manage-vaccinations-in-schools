region="eu-west-2"
service_name=""
env=${args[environment]}
task_id=${args[--task-id]}
task_ip=${args[--task-ip]}


if [ "$env" == "production" ]; then
    echo "You are trying to shell into a production container NOT Data-Replication. If you wish to proceed type 'production':"
    read -r confirm
    if [ "$confirm" != "production" ]; then
        echo "Validation failed. Exiting without shelling into production container."
        exit 1
    fi
fi

set_service_name
set_cluster_name

authenticate_user

set_task_info

echo "Opening an interactive shell in task $task_id" of service "$service_name"
aws ecs execute-command --region "$region" \
    --cluster "$cluster_name" \
    --task "$task_id" \
    --container "$container_name" \
    --command "/rails/bin/docker-entrypoint /bin/bash" \
    --interactive
