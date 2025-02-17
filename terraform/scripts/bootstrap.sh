#!/usr/bin/env bash

initialize_terraform () {
    cat << EOF > "bootstrap-$ENV.hcl" || { echo "Failed bootstrap file creation"; exit 1; }
path = "terraform-$ENV.tfstate"
EOF

  terraform init -reconfigure -backend-config="bootstrap-$ENV.hcl"; INIT_STATUS=$?
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
bucket         = "nhse-mavis-terraform-state-$ENV"
key            = "terraform-$ENV.tfstate"
region         = "$REGION"
dynamodb_table = "mavis-state-lock-$ENV"
EOF
  cat << EOF > "$ENV.tfvars" || { echo "Failed environment variables file creation"; exit 1; }
environment = "$ENV"
rails_master_key_path = "CHANGE_ME"
db_secret_arn = null
db_secret_arn = null
resource_name = {
  dbsubnet_group     = "mavis-$ENV-rds-subnet"
  db_cluster         = "mavis-$ENV-rds-cluster"
  rds_security_group = "mavis-$ENV-rds-sg"
  loadbalancer       = "mavis-$ENV-alb"
  lb_security_group = "mavis-$ENV-alb-sg"
  cloudwatch_vpc_log_group = "mavis-$ENV-FlowLogs"
}
EOF
}

create_docker_build_script () {
  cd "$DIR" || { echo "Could not return to script directory, $DOCKER_SCRIPT script not generated"; exit 1; }
  repositoryURI=$(aws ecr describe-repositories --region $REGION --repository-names mavis-$ENV | jq -r .repositories[0].repositoryUri)
  cat << EOF > $DOCKER_SCRIPT
#!/usr/bin/env bash
TAG="\$1"
if [ "\$#" -ne 1 ]; then
    echo "Usage: $0 <IMAGE_TAG>"
    exit 1
elif [ -n "\$(echo "\$TAG" | tr -d 'a-zA-Z0-9_.-')" ] ; then
   echo "Invalid tag value. Only lowercase and uppercase letters, digits, underscores, periods, and hyphens are allowed"
   exit 1
fi
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${repositoryURI%/*}" || { echo "Login failed"; exit 1; }
docker build -t "mavis-$ENV" . || { echo "Build failed"; exit 1; }
docker tag "mavis-$ENV":"\$TAG" "$repositoryURI":"\$TAG" || { echo "Tagging failed"; exit 1; }
docker push "$repositoryURI":"\$TAG" || { echo "Push failed"; exit 1; }
EOF
  chmod +x $DOCKER_SCRIPT
}

ENV="$1"
REGION=eu-west-2
DIR=$(pwd)
DOCKER_SCRIPT=docker_build_$ENV.sh

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <Environment name>"
    exit 1
elif [ -n "$(echo "$ENV" | tr -d 'a-z0-9')" ] ; then
   echo "Invalid environment string. Only lowercase alphanumeric characters are allowed"
   exit 1
fi

run_bootstrap
create_environment_files
create_docker_build_script

echo ""
echo "##########################################"
echo "########## Setup complete ################"
echo "##########################################"
echo ""
echo "Next steps:"
echo "    - To deploy terraform configuration go into the ../app directory and execute: \`terraform apply -var-file=\"env/$ENV.tfvars\"\`"
echo "    - Remember to publish a docker image to the newly created repository (mavis-$ENV) before applying the terraform configuration."
echo "    - To build the docker image, execute \`$DIR/$DOCKER_SCRIPT <IMAGE_TAG>\` in the same directory as your dockerfile"

exit 0
