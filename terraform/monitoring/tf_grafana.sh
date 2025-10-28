#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <environment> [plan|apply|destroy] [--plan-file PLAN_FILE]"
  echo "  environment               Environment to deploy to (development|production)"
  echo "  plan                      Run terraform plan for Grafana configuration"
  echo "  apply                     Run terraform apply for Grafana configuration"
  echo "  apply --plan-file FILE    Apply using a specific plan file"
  echo "  destroy                   Destroy Grafana configuration"
  echo "  -h, --help                Show this help message"
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="$1"
shift

# Validate environment parameter
if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "production" ]]; then
  echo "Error: Environment must be 'development' or 'production'"
  usage
  exit 1
fi

ACTION=""
PLAN_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    plan|apply|destroy)
      if [[ -n "$ACTION" ]]; then
        echo "Error: Multiple actions specified"
        usage
        exit 1
      fi
      ACTION="$1"
      shift
      ;;
    --plan-file)
      PLAN_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Invalid option $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$ACTION" ]]; then
  echo "Error: Action (plan|apply|destroy) is required"
  usage
  exit 1
fi
terraform -chdir="./aws" init -backend-config="env/${ENVIRONMENT}-backend.hcl" -upgrade -reconfigure
GRAFANA_ENDPOINT="https://$(terraform -chdir="./aws" output -raw grafana_endpoint)"
WORKSPACE_ID=$(terraform -chdir="./aws" output -raw grafana_workspace_id)
SERVICE_ACCOUNT_ID=$(terraform -chdir="./aws" output -raw service_account_id)
SERVICE_ACCOUNT_TOKEN=""

if ! { [[ -n "$PLAN_FILE" ]] && [[ "$ACTION" == "apply" ]]; }; then
  SERVICE_ACCOUNT_TOKEN=$(aws grafana create-workspace-service-account-token \
                     --name grafana-token-$(uuidgen) \
                     --seconds-to-live 600 \
                     --service-account-id "$SERVICE_ACCOUNT_ID" \
                     --workspace-id "$WORKSPACE_ID" \
                     --query 'serviceAccountToken.key' \
                     --output text)
fi


if [[ -z "$GRAFANA_ENDPOINT" ]] || [[ -z "$SERVICE_ACCOUNT_ID" ]]; then
  echo "Terraform variables are not set. Please run 'terraform -chdir=./aws apply -var-file=env/${ENVIRONMENT}-backend.hcl' first."
  exit 1
fi

terraform -chdir="./grafana" init -backend-config="env/${ENVIRONMENT}-backend.hcl" -upgrade -reconfigure

terraform_arguments=(-var="workspace_url=$GRAFANA_ENDPOINT" -var="service_account_token=$SERVICE_ACCOUNT_TOKEN" -var="environment=$ENVIRONMENT")

case "$ACTION" in
  plan)
    if [[ -n "$PLAN_FILE" ]]; then
      terraform -chdir="./grafana" plan "${terraform_arguments[@]}" -out="$PLAN_FILE"
    else
      terraform -chdir="./grafana" plan "${terraform_arguments[@]}"
    fi
    ;;
  apply)
    if [[ -n "$PLAN_FILE" ]]; then
      terraform -chdir="./grafana" apply "$PLAN_FILE"
    else
      terraform -chdir="./grafana" apply "${terraform_arguments[@]}"
    fi
    ;;
  destroy)
    terraform -chdir="./grafana" destroy "${terraform_arguments[@]}"
    ;;
  *)
    usage
    exit 1
    ;;
esac

# Cleanup expired tokens
REGION="eu-west-2"
CURRENT_DATE=$(date -u +%s)
TOKENS=$(aws grafana list-workspace-service-account-tokens \
    --workspace-id "$WORKSPACE_ID" \
    --service-account-id "$SERVICE_ACCOUNT_ID" \
    --region "$REGION" \
    --query 'serviceAccountTokens[*].[id,name,expiresAt]' \
    --output json)

for token in $(echo "$TOKENS" | jq -c '.[]'); do
    TOKEN_ID=$(echo "$token" | jq -r '.[0]')
    TOKEN_NAME=$(echo "$token" | jq -r '.[1]')
    EXPIRATION=$(echo "$token" | jq -r '.[2]')
    # Check if token is expired
    if [ "$EXPIRATION" != "null" ]; then
        EXPIRATION_DATE=$(date -d "$EXPIRATION" +%s 2>/dev/null || true)
        if [ -n "$EXPIRATION_DATE" ] && [ "$EXPIRATION_DATE" -lt "$CURRENT_DATE" ]; then
            aws grafana delete-workspace-service-account-token \
                --workspace-id "$WORKSPACE_ID" \
                --service-account-id "$SERVICE_ACCOUNT_ID" \
                --token-id "$TOKEN_ID" \
                --region "$REGION" >/dev/null
            echo "Deleted expired token (ID: $TOKEN_ID, NAME: $TOKEN_NAME)"
        fi
    else
        echo -e "\e[33m WARN: Token had no expiration data and was skipped (ID: $TOKEN_ID, NAME: $TOKEN_NAME)\e[0m"
    fi
done
