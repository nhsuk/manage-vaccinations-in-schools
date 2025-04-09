# Terraform manual

The Mavis infrastructure is managed with terraform. For a detailed overview over the
infrastructure see [infrastructure-overview.md](../terraform/documentation/infrastructure-overview.md).

## Setup

### AWS profile

The setup is configured to use aws profiles to prevent having to copy secrets multiple times, this means you need to
create
an aws credentials file (if you don't have one already)

```bash
mkdir $HOME/.aws
touch credentials
```

and add the following text

```bash
[default]
aws_access_key_id=...
aws_secret_access_key=...
aws_session_token=...
```

Before running `terraform ...` make sure you set the environment variable

```bash
export AWS_PROFILE=default
```

### Creating a new environment

This repo contains 2 folders with terraform configuration.

- The `bootstrap` folder stores the AWS resources required for remote state management of the app infrastructure.
  For that purpose, it just contains an S3 bucket and a DynamoDB.
- The `app` folder contains the actual infrastructure config for the app.

To set up everything from scratch, run `./bootstrap.sh <ENV_NAME>` first in the `scripts` folder and follow the
instructions from the output.

If this environment is not yet included in the allowed values of variable "environment"
in [variables.tf](app%2Fvariables.tf)
this must be updated.

### Configuring the terraform backend

The POC demonstrates a multi-backend configuration. Just run

```bash
terraform init -backend-config=env/<config-file>
```

in the `app` directory to select which environment/state-file you want.

## Shell Access

Shell access into the running app is possible using the AWS CLI and
the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html).

Run

```bash
./scripts/shell-access <CLUSTER-NAME>
```

to open an interactive shell to the container running in the specified cluster.

https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html

## Local deployment

Step 1: Build and push a docker image
```bash
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 393416225559.dkr.ecr.eu-west-2.amazonaws.com
docker build -t mavis/webapp .
docker tag mavis/webapp:latest 393416225559.dkr.ecr.eu-west-2.amazonaws.com/mavis/webapp:<GIT_SHA>
docker push 393416225559.dkr.ecr.eu-west-2.amazonaws.com/mavis/webapp:<GIT_SHA>
```

Step 2: Apply the terraform changes
* Fetch the image digest of the docker image from ECR and run the following commands
```bash
env=... # The environment to deploy  
cd terraform/app
terraform init -reconfigure -backend-config=env/$env-backend.hcl
tf apply -var-file=env/$env.tfvars -var="image_digest=$env"
```
Step 3: Run Codedeploy from the AWS Console
Step 4: If needed, trigger a deployment for the good-job service from the AWS ECS Console
