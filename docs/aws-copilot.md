# AWS Copilot Ops Manual

## Configure AWS local credentials

Install `awscli` and `aws-copilot`. Then configure your AWS CLI credentials
locally:

```bash
$ aws configure sso
```

Use any session name that makes sense to you, the SSO Start URL and SSO Region
from the "Command line or programmatic access" link in the AWS Account admin.

Once you're done, your `~/.aws/config` should look something like:

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

You can make the new profile the default by changing the config to:

```diff
[default]
-region = eu-west-2
-[profile Admin-ACCOUNT_ID]
sso_session = SESSION_NAME
sso_account_id = ACCOUNT_ID
sso_role_name = Admin
region = eu-west-2
[sso-session SESSION_NAME]
sso_start_url = https://SUBDOMAIN.awsapps.com/start#
sso_region = eu-west-2
sso_registration_scopes = sso:account:access
```

Running `aws sso login` will log you in via your browser.

After this, AWS Copilot commands should run on your new profile:

```bash
$ copilot app ls
manage-childrens-vaccinations
```

## Manual deployment

Assuming you have an environment setup, go ahead and deploy:

```bash
copilot svc deploy --env staging
```

## Opening a shell on the remote environment

If you have the service up and running, you can connect to the first running
container with this command:

```bash
copilot svc exec --app manage-childrens-vaccinations --env staging --name webapp
```

### Tailing logs of running service

Use this command to see the most recent logs and to follow any new logs:

```bash
copilot svc logs --since 1h --follow
```

## Setting up a new environment

Before you start, if you want HTTPS, you need to set up certificates in ACM.

The certificate needs to be verified by the DNS team by sending them the
verification `cname`. On their end, they will verify the ownership, which in
turn will update the status of the certificate to 'verified' in the ACM List of
Certificates.

Once the cert is approved, feed the ARN using the CLI:

```bash
copilot env init --import cert arn:aws.....
```

This will change the manifest file for the environment:

```
http:
  public:
    certificates: [arn:aws:acm:eu-west-2:393416225559:certificate/05611645-54eb-4bfe-bace-58d64f27c974]
```

Give the environment a name and choose the default environment configuration.

`copilot env ls` should show the new environment when the previous command
succeeds.

Deploy the env once, so that it is upgraded, and allows us to provision
secrets:

```bash
copilot env deploy --name pentest
```

Open `copilot/webapp/manifest.yml` and add a new section to the `environments`:

```diff
environments:
  staging:
    variables:
      RAILS_ENV: staging
      MAVIS__SUPPORT_USERNAME: manage
      MAVIS__SUPPORT_PASSWORD: vaccinations
    http:
      alias:
        - "staging.manage-vaccinations-in-schools.nhs.uk"
        - "staging.give-or-refuse-consent-for-vaccinations.nhs.uk"
+  pentest:
+    variables:
+      RAILS_ENV: staging
+      MAVIS__SUPPORT_USERNAME: manage
+      MAVIS__SUPPORT_PASSWORD: vaccinations
+    http:
+      alias:
+        - "pentest.manage-vaccinations-in-schools.nhs.uk"
+        - "pentest.give-or-refuse-consent-for-vaccinations.nhs.uk"
```

You'll then need to set up the secrets. Check the `secrets` section of the
`webapp/manifest.yml`. Set up each one with:

```bash
copilot secret init
```

Skip the environments you're not setting up keys for by hitting return.

Finally, deploy the app:

```bash
copilot svc deploy --env pentest
```

When you're done with the environment, you can tear it down with:

```bash
copilot svc delete --name pentest
copilot env delete --name pentest
```

### Using the mavistesting.com domain

The staging AWS subscription has ownership of the `mavistesting.com` domain.
It's purpose is to assist with debugging Copilot environment related issues
that require re-provisioning of environments from scratch.

This is only necessary to change things like load balancer settings, SSL
security policies.

To deploy to it, create a new environment in the usual way, but remove the ARNs
from the `manifest.yml` for your new environment. Specify what domains you'd
like to use in the `webapp/manifest.yml`:

```diff
  pentest:
    http:
      alias:
+        - "test.mavistesting.com"
    deployments:
      rolling: recreate
```

### Cheat sheet

```bash
copilot env init --name test     # Initialise a new environment
copilot env deploy --name test   # Deploy the new environment
copilot secret init              # Add a secret to every environment
copilot svc deploy --env test    # Deploy the web app

copilot svc delete --name test   # Destroy the web app
copilot env delete --name test   # Destroy the environment
```

### Loading example campaigns in a new environment

Demonstration of how to prepare a new environment by loading the example campaigns. `bash` is started simply because the default shell is really barebones.

```
$ copilot svc exec --app manage-vaccinations-in-schools --env staging --name webapp
Execute `/bin/sh` in container webapp in task 638cda17ed0b424fb45ccf7e051f1ed1.

Starting session with SessionId: ecs-execute-command-08951764cb092ca09
# bash
root@ip-10-0-0-77:/rails# bin/rails load_campaign_example[db/sample_data/example-hpv-campaign.json]
root@ip-10-0-0-77:/rails# bin/rails load_campaign_example[db/sample_data/example-flu-campaign.json] new_campaign=1
```

## GitHub Actions Custom IAM Role

### Role Details

```
Role Name: GitHubActionsRole
Role ARN: arn:aws:iam::393416225559:role/GitHubActionsRole
```

### Purpose

The primary purpose of this role is to allow GitHub Actions workflows to securely interact with AWS services. This includes deploying applications, managing AWS resources, and executing various AWS operations required by our CI/CD pipeline.

### Permissions

The role includes the following permissions:

- Amazon Elastic Container Service (ECS)
- Amazon Elastic Container Registry (ECR)
- Elastic Load Balancing (ELB)
- Amazon Virtual Private Cloud (VPC)
- AWS CloudFormation
- Amazon Simple Storage Service (S3)
- AWS Secrets Manager or AWS Systems Manager (Parameter Store)
- Security Token Service (STS)

### Trust Relationship

The role is configured with a trust relationship to allow GitHub Actions to assume this role. The trust policy is as follows:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::393416225559:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:nhsuk/manage-childrens-vaccinations:*"
        }
      }
    }
  ]
}
```

### Usage in GitHub Actions

The role is used in GitHub Actions workflows as follows:

Configured in the workflow YAML file using aws-actions/configure-aws-credentials action.
The role is assumed to provide temporary credentials for the workflow to interact with AWS services.

```
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v1
  with:
    role-to-assume: arn:aws:iam::393416225559:role/GitHubActionsRole
    aws-region: eu-west-2
```

### Security and Best Practices

The role follows the principle of least privilege, granting only the permissions necessary for the tasks performed by GitHub Actions.
Regular audits and reviews are to be conducted to ensure the role's permissions align with current requirements.

## aws-account-setup script notes

### Purpose

This is a shell script designed to automate the setup of IAM Access Analyzers in an AWS account. It checks for the existence of two specific types of analyzers - ACCOUNT and ACCOUNT_UNUSED_ACCESS - and creates them if they do not exist. This script is useful for ensuring compliance with security best practices in AWS environments.

### Functionality

**Analyzer Check**: The script first checks if the specified analyzers (External Access and Unused Access) exist in the AWS account.\
**Creation**: If either analyzer is not present, the script proceeds to create it.\
**Error Handling**: Includes basic error handling; exits upon failure to create an analyzer.\
NOTE: The script executes non-interactively without requiring manual input.

### Requirements

- AWS CLI installed and configured.
- User must have permissions to manage IAM Access Analyzer.

### Usage

Run the following from the root of the project directory:

```
bin/aws-account-setup
```
