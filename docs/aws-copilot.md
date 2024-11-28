# AWS Copilot Ops Manual

## Configure AWS credentials

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

After this, AWS Copilot commands should run on your default profile:

```bash
$ copilot app ls
mavis
```

## Ops cheat sheet

### Manual deployment

```bash
copilot svc deploy --env test
```

### Shelling in

```bash
copilot svc exec --env test
```

### Tailing logs

```bash
copilot svc logs --since 1h --follow
```

### Add a new secret

Add an entry to `copilot/webapp/manifest.yml` manually, then run `copilot secret
init` to add the secrets to the AWS System Manager's Parameters Store.

## Setting up a new environment

### Quick start

```bash
copilot env init --name test                # Initialise a new environment
copilot env deploy --name test              # Deploy the new environment
copilot secret init                         # Add a secret to every environment

copilot svc init --name webapp --env test   # Only needed if service doesn't
                                            # exist in subscription
copilot svc deploy --env test               # Deploy the web app

                                            # Disable deletion protection on RDS

copilot svc delete --name webapp --env test # Destroy the web app
copilot env delete --name test              # Destroy the environment disable
                                            # deletion protection if necessary
```

### Full guide

Before you start, if you want HTTPS, you need to set up certificates in ACM.

The certificate needs to be verified by the DNS organisation by sending them the
verification `cname`. On their end, they will verify the ownership, which in
turn will update the status of the certificate to 'verified' in the ACM List of
Certificates.

Once the cert is approved, feed the ARN using the CLI:

```bash
copilot env init --import-cert-arns arn:aws.....
```

This will change the manifest file for the environment:

```
http:
  public:
    certificates: [arn:aws:acm:eu-west-2:393416225559:certificate/05611645-54eb-4bfe-bace-58d64f27c974]
```

You can also manually edit the environment file and specify the cert, in case
the `env` has already been `init`.

Give the environment a name and choose the default environment configuration.

To check that the environment was provisioned successfully:

```bash
copilot env ls
```

Deploy the environment once, so that it is upgraded, and allows us to provision
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
copilot svc init # Only necessary if service doesn't exist in subscription
copilot svc deploy --env pentest
```

When you're done with the environment, you can tear it down with:

```bash
copilot svc delete --name pentest
copilot env delete --name pentest
```

### Using the mavistesting.com domain

The test/training AWS subscription has ownership of the `mavistesting.com`
domain. It's purpose is to assist with debugging Copilot environment related
issues that require re-provisioning of environments from scratch.

This is only necessary to change things like load balancer settings or SSL
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

## GitHub Actions Custom IAM Role

There is a predefined IAM role to facilitate continuous deployment.

### Role Details

```
Role Name: GitHubActionsRole
Role ARN: arn:aws:iam::393416225559:role/GitHubActionsRole
```

### Permissions

- Amazon Elastic Container Service (ECS)
- Amazon Elastic Container Registry (ECR)
- Elastic Load Balancing (ELB)
- Amazon Virtual Private Cloud (VPC)
- AWS CloudFormation
- Amazon Simple Storage Service (S3)
- AWS Secrets Manager or AWS Systems Manager (Parameter Store)
- Security Token Service (STS)

### AWS trust policy

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
          "token.actions.githubusercontent.com:sub": "repo:nhsuk/manage-vaccinations-in-schools:*"
        }
      }
    }
  ]
}
```

### Usage in GitHub Actions

```
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v1
  with:
    role-to-assume: arn:aws:iam::393416225559:role/GitHubActionsRole
    aws-region: eu-west-2
```

## `script/aws-account-setup.sh` script

### Purpose

This is a shell script designed to automate the setup of IAM Access Analyzers in
an AWS account.

It checks for the existence of two specific types of analyzers - ACCOUNT and
ACCOUNT_UNUSED_ACCESS - and creates them if they do not exist. This script is
useful for ensuring compliance with security best practices in AWS environments.

### Usage

```
bash script/aws-account-setup.sh
```

## Troubleshooting

### Deployment error: `denied: Your authorization token has expired. Reauthenticate and try again.``

This can occur if your docker client has some old state left in it. Logging out
seems to fix it:

```
docker logout https://393416225559.dkr.ecr.eu-west-2.amazonaws.com
```
