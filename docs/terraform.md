# Terraform manual

The Mavis infrastructure is managed with terraform. For a detailed overview over the
infrastructure see [infrastructure-overview.md](../terraform/documentation/infrastructure-overview.md).

## Setup

### AWS profile

To set up `awscli` for the first time:

```bash
aws configure sso
```

Your `~/.aws/config` should look something like:

```bash
[default]
region = eu-west-2
[profile Admin-ACCOUNT_ID]
sso_session = SESSION_NAME
sso_account_id = ACCOUNT_ID
sso_role_name = Admin
region = eu-west-2
[sso-session SESSION_NAME]
sso_start_url = https://SUBDOMAIN.awsapps.com/start#
sso_region = eu-west-2
sso_registration_scopes = sso:account:access
```

Before running `terraform ...` make sure you set the environment variable to the desired profile

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
scripts/shell.sh <CLUSTER-NAME>
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

- Fetch the image digest of the docker image from ECR and run the following commands

```bash
env=... # The environment to deploy
cd terraform/app
terraform init -reconfigure -backend-config=env/$env-backend.hcl
tf apply -var-file=env/$env.tfvars -var="image_digest=<image_digest_from_ECR>"
```

Step 3: Run Codedeploy from the AWS Console
Step 4: If needed, trigger a deployment for the good-job service from the AWS ECS Console

For a more high-level description of the process see [deployment-process.md](../terraform/documentation/deployment-process.md)
