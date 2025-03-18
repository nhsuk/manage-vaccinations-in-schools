#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

environment=$1

terraform init -backend-config="env/${environment}-backend.hcl" -upgrade
APPLICATION_NAME=$(terraform output -json codedeploy_application_name | tr -d '"') || { echo "No CodeDeploy application found in the current terraform state. Skipping check for running deployment."; exit 0; }
echo "Application Name: $APPLICATION_NAME"
APPLICATION_GROUP=$(terraform output -json codedeploy_deployment_group_name | tr -d '"') || { echo "No CodeDeploy application found in the current terraform state. Skipping check for running deployment."; exit 0; }
echo "Deployment Group Name: $APPLICATION_GROUP"

running_deployment=$(aws deploy list-deployments --application-name $APPLICATION_NAME \
    --deployment-group-name $APPLICATION_GROUP --include-only-statuses InProgress \
    --query 'deployments[0]' --output text)
if [ "$running_deployment" != "None" ]; then
  echo "A mavis deployment for ${environment} is currently running: $running_deployment"
  echo "Aborting infrastructure deployment"
  exit 1
fi
