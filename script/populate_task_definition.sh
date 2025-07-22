#!/usr/bin/env bash

set -e

# Usage function
usage() {
    echo "Usage: $0 <environment> <server_type> [options]"
    echo ""
    echo "Arguments:"
    echo "  environment  : Environment name (e.g., sandbox-alpha, production)"
    echo "  server_type  : Server type (web or good-job)"
    echo ""
    echo "Options:"
    echo "  -o, --output FILE     : Output file path (default: task-definition.json)"
    echo "  -t, --template FILE   : Template file path (default: config/templates/task-definition.json.tpl)"
    echo "  -i, --image URI       : Docker image URI (required)"
    echo "  -c, --cpu VALUE       : CPU units (default: 1024)"
    echo "  -m, --memory VALUE    : Memory in MB (default: 2048)"
    echo "  -h, --help            : Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 sandbox-alpha web -i 123456789.dkr.ecr.eu-west-2.amazonaws.com/mavis/webapp:latest"
    echo "  $0 sandbox-alpha good-job -i 123456789.dkr.ecr.eu-west-2.amazonaws.com/mavis/webapp:latest -o good-job-task-definition.json"
    exit ${1:-1}
}

# Default values
output_file="task-definition.json"
template_file="config/templates/task-definition.json.tpl"
cpu="1024"
memory="2048"
image_uri=""
health_check_path="/"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            output_file="$2"
            shift 2
            ;;
        -t|--template)
            template_file="$2"
            shift 2
            ;;
        -i|--image)
            image_uri="$2"
            shift 2
            ;;
        -c|--cpu)
            cpu="$2"
            shift 2
            ;;
        -m|--memory)
            memory="$2"
            shift 2
            ;;
        -h|--help)
            usage 0
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            if [ -z "$environment" ]; then
                environment="$1"
            elif [ -z "$server_type" ]; then
                server_type="$1"
            else
                echo "Too many arguments"
                usage
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [ -z "$environment" ] || [ -z "$server_type" ]; then
    echo "Error: Environment and server_type are required"
    usage
fi

if [ -z "$image_uri" ]; then
    echo "Error: Docker image URI is required (use -i or --image)"
    usage
fi

# Check if template file exists
if [ ! -f "$template_file" ]; then
    echo "Error: Template file '$template_file' not found"
    exit 1
fi

# Validate server_type
if [[ "$server_type" == "web" ]]; then
    health_check_path="/health/database"
elif [[ "$server_type" == "good-job" ]]; then
    health_check_path="/status/connected"
else
    echo "Error: server_type must be 'web' or 'good-job'"
    exit 1
fi

# Fetch SSM parameter
ssm_parameter_name="/${environment}/ecs/${server_type}/container_variables"
echo "Fetching SSM parameter: $ssm_parameter_name"

ssm_output=$(aws ssm get-parameter --name "$ssm_parameter_name" --query Parameter.Value --output text)
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch SSM parameter '$ssm_parameter_name'"
    exit 1
fi

# Parse JSON using jq
execution_role_arn=$(echo "$ssm_output" | jq -r '.execution_role_arn')
task_role_arn=$(echo "$ssm_output" | jq -r '.task_role_arn')

# Function to escape special characters for sed
escape_for_sed() {
    printf '%s\n' "$1" | sed 's/[[\.*^$()+?{|]/\\&/g'
}

# Extract environment variables and create a temporary file for processing
env_vars_json=$(echo "$ssm_output" | jq -r '.task_envs')
secrets_json=$(echo "$ssm_output" | jq -r '.task_secrets')

# Start with the template
cp "$template_file" "$output_file"

# Replace basic placeholders
sed -i "s|<ENV>|$environment|g" "$output_file"
sed -i "s|<SERVER_TYPE>|$server_type|g" "$output_file"

# Replace role ARNs (escape special characters)
escaped_task_role_arn=$(escape_for_sed "$task_role_arn")
escaped_execution_role_arn=$(escape_for_sed "$execution_role_arn")
escaped_health_check_path=$(escape_for_sed "$health_check_path")
sed -i "s|<TASK_ROLE_ARN>|$escaped_task_role_arn|g" "$output_file"
sed -i "s|<EXECUTION_ROLE_ARN>|$escaped_execution_role_arn|g" "$output_file"
sed -i "s|<HEALTH_CHECK_PATH>|$escaped_health_check_path|g" "$output_file"
# Function to extract value from environment variables
get_env_value() {
    local var_name="$1"
    echo "$env_vars_json" | jq -r --arg name "$var_name" '.[] | select(.name == $name) | .value'
}

# Function to extract valueFrom from secrets
get_secret_value() {
    local var_name="$1"
    echo "$secrets_json" | jq -r --arg name "$var_name" '.[] | select(.name == $name) | .valueFrom'
}

# Replace environment variable placeholders
sed -i "s|<MAVIS__GIVE_OR_REFUSE_CONSENT_HOST>|$(escape_for_sed "$(get_env_value "MAVIS__GIVE_OR_REFUSE_CONSENT_HOST")")|g" "$output_file"
sed -i "s|<RAILS_ENV>|$(escape_for_sed "$(get_env_value "RAILS_ENV")")|g" "$output_file"
sed -i "s|<SPLUNK__ENABLED>|$(escape_for_sed "$(get_env_value "MAVIS__SPLUNK__ENABLED")")|g" "$output_file"
sed -i "s|<MAVIS__HOST>|$(escape_for_sed "$(get_env_value "MAVIS__HOST")")|g" "$output_file"
sed -i "s|<CIS2__ENABLED>|$(escape_for_sed "$(get_env_value "MAVIS__CIS2__ENABLED")")|g" "$output_file"
sed -i "s|<DB_NAME>|$(escape_for_sed "$(get_env_value "DB_NAME")")|g" "$output_file"
sed -i "s|<DB_HOST>|$(escape_for_sed "$(get_env_value "DB_HOST")")|g" "$output_file"
sed -i "s|<APP_VERSION>|$(escape_for_sed "$(get_env_value "APP_VERSION")")|g" "$output_file"

# Replace secret placeholders
sed -i "s|<DB_SECRET_ARN>|$(escape_for_sed "$(get_secret_value "DB_CREDENTIALS")")|g" "$output_file"
sed -i "s|<RAILS_MASTER_KEY_ARN>|$(escape_for_sed "$(get_secret_value "RAILS_MASTER_KEY")")|g" "$output_file"
sed -i "s|<GOOD_JOB_MAX_THREADS_ARN>|$(escape_for_sed "$(get_secret_value "GOOD_JOB_MAX_THREADS")")|g" "$output_file"
sed -i "s|<MAVIS__PDS__ENQUEUE_BULK_UPDATES_ARN>|$(escape_for_sed "$(get_secret_value "MAVIS__PDS__ENQUEUE_BULK_UPDATES")")|g" "$output_file"
sed -i "s|<MAVIS__PDS__WAIT_BETWEEN_JOBS_ARN>|$(escape_for_sed "$(get_secret_value "MAVIS__PDS__WAIT_BETWEEN_JOBS")")|g" "$output_file"

# Replace additional placeholders
escaped_image_uri=$(escape_for_sed "$image_uri")
sed -i "s|REPOSITORY_URI|$escaped_image_uri|g" "$output_file"
sed -i "s|<CPU>|$cpu|g" "$output_file"
sed -i "s|<MEMORY>|$memory|g" "$output_file"

echo "Task definition populated successfully: $output_file"
echo "Template: $template_file"
echo "Environment: $environment"
echo "Server type: $server_type"
echo "Image URI: $image_uri"
echo "CPU: $cpu"
echo "Memory: $memory"
