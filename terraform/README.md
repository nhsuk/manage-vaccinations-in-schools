# terraform-aws-poc

Terraform configuration to manage an AWS ECS Fargate service with an Aurora RDS database.
The service runs in a private subnet, accessible through a load balancer. For a detailed overview over the
infrastructure see [infrastructure-overview.md](./documentation/infrastructure-overview.md).

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

If this environment is not yet included in the allowed values of variable "environment_string"
in [variables.tf](app%2Fvariables.tf)
this must be updated.

### Configuring the terraform backend

The POC demonstrates a multi-backend configuration. Just run

```bash
terraform init -backend-config=env/<config-file>
```

in the `app` directory to select which environment/state-file you want.

### Pre-commit

We will use pre-commit to format and lint the files.

- Linting is done with `tflint` (installed with mise)
- To install pre-commit ensure you have pip installed and create a venv and activate it

```bash
python3 -m venv venv
source venv/bin/activate
```

now install pre-commit

```bash
pip install pre-commit
```

and finally activate pre-commit

```bash
pre-commit install
```

## Shell Access

Shell access into the running app is possible using the AWS CLI and
the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html).

Run

```bash
./scripts/shell-access <CLUSTER-NAME>
```

to open an interactive shell to the container running in the specified cluster.

https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html
