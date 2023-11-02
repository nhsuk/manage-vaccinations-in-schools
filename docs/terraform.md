# Deploying with Terraform

## TODO

- Look into setting temporary RAILS_ENV before running assets precompile in
  Dockerfile
- Alternatively add a IGNORE_PRODUCTION_CHECKS environment variable check to
  `check_production.rb` and use it in the Dockerfile

```sh
aws configure set region eu-west-2
aws ecr create-repository --repository-name manage-childrens-vaccinations
yay -S buildx # or macOS equivalent
```

## Building a Docker Container

You can build a Docker container the standard way, but you'll need to specify
the platform when building on Apple Silicon:

```sh
docker build --platform=linux/amd64 . -t record-childrens-vaccinations:latest
```

## Terraforming into AWS

This app can be deployed using Terraform to AWS. It is configured to deploy to
an ECS cluster that uses AWS's FARGATE. AWS RDS is used to setup Postgres as the
primary DB, and ALB is setup for load balancing.

### AWS CLI

Before deploying to AWS you'll need the AWS CLI tools installed. Try your OS's
package, for example HomeBrew's `awscli` package, if available. Also see
[Installing or updating the latest version of the AWS
CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

### Deployment Enviroment and AWS Accounts

Deployment environments are mapped to AWS accounts: each environment is a
separate AWS account. The current best practice is to do this and to link the
AWS account to a managing AWS account as part of an AWS Organisation.

### AWS Authentication

Before running AWS commands you'll need to be authenticated to the correct
account. For example, to push a new Docker image you'll need to be authenticated
to the account in which the AWS ECR was created.

To deploy to an environment be sure to authenticate to the correct account for
that environment. To authenticate, go to the "Start" page for your organisation,
then:

- click "AWS Account"
- click "Command line or programmatic access"
- then click the environment variables settings under "Option 1: Set AWS
  environment variables" to copy them
- paste these commands into your shell

The shell should now be authenticated to run `aws` commands. These credentials
time out after a short period (about a couple hours).

### Secrets

Secrets are stored in the AWS secrets manager within the AWS account for the
given deployment environment. For example secrets for the staging environment
are in the `record-childrens-vaccinations-staging` account.

### Pushing Docker image to AWS ECR

We use a public AWS Elastic Container Registry for our Docker images.

```sh
# Use AWS to authenticate with Docker. You'll need the aws cli tools installed
# (`awscli` in Homebrew) and to be logged into the AWS account that owns the
# Elastic Container Repository (ECR). All public repositories are in us-east-1
# region.
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/z8i3v8n4

docker push public.ecr.aws/z8i3v8n4/record-childrens-vaccinations:latest
```

### Terraform and Deployment Environments

We use Terraform workspaces to deploy to different environments. Eack workspace
has it's won Terraform state file, so make sure you switch to the appropriate
workspace when running Terraform.

```sh
# Create a new workspace for staging if necessary
terraform -chdir=terraform workspace new staging

# Switch to the staging workspace
terraform -chdir=terraform workspace select staging
```

### Terraforming

Once ready you can plan and apply the latest Terraform config:

```sh
# Use plan to see what's changing and as a sanity check.
terraform -chdir=terraform plan

# Fireworks time.
terraform -chdir=terraform apply
```
