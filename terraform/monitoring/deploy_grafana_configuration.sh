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
  echo "Error: Action is required"
  usage
  exit 1
fi

GRAFANA_ENDPOINT=$(terraform output -raw grafana_endpoint)
WORKSPACE_ID=$(terraform output -raw grafana_workspace_id)
SERVICE_ACCOUNT_ID=$(terraform output -raw grafana_service_account_id)
GRAFANA_API_KEY=$(aws grafana create-workspace-service-account-token \
                   --name grafana-token-$(uuidgen) \
                   --seconds-to-live 600 \
                   --service-account-id 4 \
                   --workspace-id g-8c11674eda \
                   --query 'serviceAccountToken.key' \
                   --output text)

if [[ -z "$GRAFANA_ENDPOINT" ]] || [[ -z "$GRAFANA_API_KEY" ]] || [ -z "$WORKSPACE_ID" ]] || [[ -z "$SERVICE_ACCOUNT_ID" ]]; then
  echo "Grafana endpoint or API key is not set. Please run 'terraform apply -env-file=env/<account>-backend.hcl' first."
  exit 1
fi

cd ../grafana

case "$ACTION" in
  plan)
    terraform plan -var="grafana_endpoint=$GRAFANA_ENDPOINT" -var="grafana_api_key=$GRAFANA_API_KEY"
    ;;
  apply)
    if [[ -n "$PLAN_FILE" ]]; then
      terraform apply "$PLAN_FILE"
    else
      terraform apply -var="grafana_endpoint=$GRAFANA_ENDPOINT" -var="grafana_api_key=$GRAFANA_API_KEY" -auto-approve
    fi
    ;;
  destroy)
    terraform destroy -var="grafana_endpoint=$GRAFANA_ENDPOINT" -var="grafana_api_key=$GRAFANA_API_KEY" -auto-approve
    ;;
  *)
    usage
    exit 1
    ;;
esac
