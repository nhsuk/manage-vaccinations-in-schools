#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [plan|apply|destroy] [--plan-file PLAN_FILE]"
  echo "  plan                      Run terraform plan for Grafana configuration"
  echo "  apply                     Run terraform apply for Grafana configuration"
  echo "  apply --plan-file FILE    Apply using a specific plan file"
  echo "  destroy                   Destroy Grafana configuration"
  echo "  -h, --help                Show this help message"
}

if [[ $# -lt 1 ]]; then
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
  echo "Terraform variables are not set. Please run 'terraform -chdir=./aws apply -var-file=env/<account>-backend.hcl' first."
  exit 1
fi

terraform -chdir="./grafana" init -backend-config="env/development-backend.hcl" -reconfigure

case "$ACTION" in
  plan)
    if [[ -n "$PLAN_FILE" ]]; then
      terraform -chdir="./grafana" plan -var="workspace_url=$GRAFANA_ENDPOINT" -var="service_account_token=$SERVICE_ACCOUNT_TOKEN" -out="$PLAN_FILE"
    fi
    terraform -chdir="./grafana" plan -var="workspace_url=$GRAFANA_ENDPOINT" -var="service_account_token=$SERVICE_ACCOUNT_TOKEN"
    ;;
  apply)
    if [[ -n "$PLAN_FILE" ]]; then
      terraform -chdir="./grafana" apply "$PLAN_FILE"
    else
      terraform -chdir="./grafana" apply -var="workspace_url=$GRAFANA_ENDPOINT" -var="service_account_token=$SERVICE_ACCOUNT_TOKEN"
#      terraform -chdir="./grafana" apply -var="workspace_url=$GRAFANA_ENDPOINT" -var="service_account_token=$SERVICE_ACCOUNT_TOKEN" -auto-approve
    fi
    ;;
  destroy)
    terraform -chdir="./grafana" destroy -var="workspace_url=$GRAFANA_ENDPOINT" -var="service_account_token=$SERVICE_ACCOUNT_TOKEN"
    ;;
  *)
    usage
    exit 1
    ;;
esac
