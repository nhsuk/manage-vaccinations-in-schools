function confirm_production {
    if [ "$env" == "production" ]; then
        echo "You are trying to shell into a production container NOT Data-Replication. If you wish to proceed type 'production':"
        read -r confirm
        if [ "$confirm" != "production" ]; then
            echo "Validation failed. Exiting without shelling into production container."
            exit 1
        fi
    fi
}

function list_running_tasks {
    local service_name="$1"
    if [ -n "$service_name" ]; then
        aws ecs list-tasks --region "$region" --cluster "$cluster_name" --service-name "$service_name" --desired-status RUNNING | jq -r '.taskArns[]'
    else
        aws ecs list-tasks --region "$region" --cluster "$cluster_name" --desired-status RUNNING | jq -r '.taskArns[]'
    fi
}

function describe_tasks {
    local task_arns="$1"
    aws ecs describe-tasks --region "$region" --cluster "$cluster_name" --tasks $task_arns
}

function select_running_container { 
    local task_data="$1"
    echo "$task_data" | jq -r '.containers | map(select(.lastStatus == "RUNNING" and .name == "application"))[0].name'
}


function set_service_name {
    # Set service to ops server for some environments, web server for others
    if [ -z "$service_name" ] && [[ "$env" != *data-replication ]]; then
        if [ "$env" == "qa" ] || [ "$env" == "production" ]; then
            service_name="mavis-$env-ops"
            service_type="ops"
        else
            service_name="mavis-$env-web"
            service_type="web"
        fi
    fi
}

function set_cluster_name() {
    cluster_name="mavis-$env"
}

function set_task_info {
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
        container_name=$(select_running_container "$(echo "$task_description" | jq '.tasks[0]')")
        if [ -z "$container_name" ] || [ "$container_name" = "null" ]; then
            echo "No running containers with valid runtimeId found in task $task_id"
            exit 1
        fi
    elif [ -n "$task_ip" ]; then
        task_arns=$(list_running_tasks "$service_name")
        if [ -z "$task_arns" ]; then
            echo "No running tasks found in cluster $cluster_name" $([ -n "$service_name" ] && echo "for service $service_name")
            exit 1
        fi
        tasks_description=$(describe_tasks "$task_arns")
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
        container_name=$(select_running_container "$task_description")
        if [ -z "$container_name" ] || [ "$container_name" = "null" ]; then
            echo "No running containers with valid runtimeId found in task $task_id"
            exit 1
        fi
    else
        task_arns=$(list_running_tasks "$service_name")
        if [ -z "$task_arns" ]; then
            echo "No running tasks found in cluster $cluster_name" $([ -n "$service_name" ] && echo "for service $service_name")
            exit 1
        fi
        tasks_description=$(describe_tasks "$task_arns")
        if [ -z "$tasks_description" ]; then
            echo "Failed to describe tasks in cluster $cluster_name"
            exit 1
        fi
        selected_task=$(echo "$tasks_description" | jq '.tasks | map(select(.containers | map(.lastStatus == "RUNNING" and .runtimeId != null) | any)) | .[0]')
        if [ -z "$selected_task" ] || [ "$selected_task" = "null" ]; then
            echo "No running tasks with running containers with valid runtimeId found in cluster $cluster_name" $([ -n "$service_name" ] && echo "for service $service_name")
            exit 1
        fi
        task_id=$(echo "$selected_task" | jq -r '.taskArn | split("/") | .[-1]')
        container_name=$(select_running_container "$selected_task")
    fi
}

function authenticate_user {
    if ! aws sts get-caller-identity &>/dev/null; then
        if [[ -z "${args[--exit-without-login]}" ]]; then
            if ! aws sso login; then
                echo "Error: AWS CLI SSO login failed. Please log in to your AWS account."
                exit 1
            fi
        else
            echo "Error: AWS SSO login required. Please log in to your AWS account using 'aws sso login'."
            exit 1
        fi
    fi
}
