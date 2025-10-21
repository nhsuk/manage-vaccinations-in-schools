#!/usr/bin/env bash

initialize_terraform () {
  terraform init -reconfigure -backend-config="path=terraform-$ENV.tfstate"; INIT_STATUS=$?
  if [ ! $INIT_STATUS -eq 0 ]; then
    echo "Terraform init failed. Please check output and fix the issue."
    exit 1
  fi
}

execute_and_verify_plan () {
  terraform plan -var="environment=$ENV" -out=$TERRAFORM_PLAN > $TERRAFORM_PLAN_READABLE
  NO_CHANGES="$(grep -n 'Your infrastructure matches the configuration' $TERRAFORM_PLAN_READABLE)"
  if [ -n "$NO_CHANGES" ]; then
    echo "No terraform changes detected"
    return 42
  fi

  PLAN_LENGTH="$(grep -n '────────' $TERRAFORM_PLAN_READABLE | grep -oE '^[0-9]+')"
  head -"$PLAN_LENGTH" "$TERRAFORM_PLAN_READABLE"

  echo "Does the plan look ok?"
  echo "Enter value (only 'yes' will be accepted): "
  read -p "       value: " -r
  if [ "$REPLY" = "yes" ]; then
    echo "Plan accepted"
  else
    echo "Cancelling terraform apply command"
    exit 2
  fi
}

apply_terraform_plan () {
  terraform apply "$TERRAFORM_PLAN"; APPLY_STATUS=$?

  STATE_LENGTH=$(terraform state list | wc -l)
  if [ $APPLY_STATUS -eq 0 ]; then
    echo "Apply was successful, $STATE_LENGTH resources were generated:"
    terraform state list
    echo "The terraform state file for these resources is only stored locally. If you are intending to persist the
     environment it is a good idea to delete the local state file to prevent accidental deletion."
  else
    echo "Terraform apply exited incorrectly"
    check_partial_apply "$STATE_LENGTH"
    exit 1
  fi
}

check_partial_apply () {
  if [ ! "$1" ]; then
    echo "No resources were created by terraform apply, this script can be run again after fixing configuration changes"
  else
    echo "Resources thus far created by terraform apply:"
    terraform state list
    echo "The terraform apply can be continued after fixing your configuration by running:"
    echo "\`terraform apply -var=\"environment=$ENV\`\""
    echo "If you wish to delete the generated resources run:"
    echo "\`terraform destroy -var=\"environment=$ENV\`\""
  fi
}

run_bootstrap () {
  cd ../bootstrap || \
  { echo "Could not cd into bootstrap directory, make sure you are calling this script from the 'scripts' directory";
    exit 1; }

  TERRAFORM_PLAN="bootstrap.plan"
  TERRAFORM_PLAN_READABLE="plan.output"

  initialize_terraform
  execute_and_verify_plan; plan_value=$?

  if [ $plan_value -eq 42 ]; then
    echo "No changes to configuration, skipping terraform apply step."
  else
    apply_terraform_plan
  fi

  rm -f $TERRAFORM_PLAN $TERRAFORM_PLAN_READABLE
}

create_environment_files () {
  cd ../app/env || \
  { echo "Could not cd into app/env directory, environment files were not created"; exit 1; }
  cat << EOF > "$ENV-backend.hcl" || { echo "Failed backend file creation"; exit 1; }
bucket         = "nhse-mavis-terraform-state"
key            = "terraform-$ENV.tfstate"
EOF
  cat << EOF > "$ENV.tfvars" || { echo "Failed environment variables file creation"; exit 1; }
environment           = "$ENV"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
dns_certificate_arn   = null
resource_name = {
  rds_security_group       = "mavis-$ENV-rds-sg"
  loadbalancer             = "mavis-$ENV-alb"
  lb_security_group        = "mavis-$ENV-alb-sg"
  cloudwatch_vpc_log_group = "mavis-$ENV-FlowLogs"
}
http_hosts = {
  MAVIS__HOST                        = "$ENV.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "$ENV.mavistesting.com"
}

enable_splunk                   = false
enable_cis2                     = false
enable_pds_enqueue_bulk_updates = false

minimum_web_replicas = 3

EOF
}

ENV="$1"

if [ "$#" == 0 ] || [ "$#" -gt 2 ] ; then
  echo "Usage: $0 <Environment name> [options]"
  echo "Options:"
  echo "  --environment-only  Skips creation of S3 bucket for terraform state (e.g. if it already exists)"
  exit 1
elif [ -n "$(echo "$ENV" | tr -d 'a-z0-9-')" ] ; then
 echo "Invalid environment string. Only lowercase alphanumeric characters and '-' are allowed"
 exit 1
elif [ -n "$2" ] && [ "$2" != "--environment-only" ] ; then
 echo "Unknown option: $2"
 exit 1
fi

if [ -z "$2" ]; then
  run_bootstrap
fi
create_environment_files

echo ""
echo "##########################################"
echo "########## Setup complete ################"
echo "##########################################"
echo ""
echo "The environment is now ready for application or infrastructure deployment via github workflows."


exit 0
