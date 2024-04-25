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
copilot env init --import-cert-arns arn:aws.....
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

The test/training AWS subscription has ownership of the `mavistesting.com`
domain.  It's purpose is to assist with debugging Copilot environment related
issues that require re-provisioning of environments from scratch.

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
copilot env init --name test                # Initialise a new environment
copilot env deploy --name test              # Deploy the new environment
copilot secret init                         # Add a secret to every environment
copilot svc deploy --env test               # Deploy the web app

copilot svc delete --name webapp --env test # Destroy the web app
copilot env delete --name test              # Destroy the environment disable
                                            # deletion protection if necessary
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

## Security Alerts using AWS CloudWatch

This guide details setting up CloudWatch alerts to monitor critical security events in AWS, starting from CloudTrail and SNS setup to creating specific CloudWatch metric filters and alarms.

### Prerequisites

- AWS CloudTrail Configured: Ensure CloudTrail is active for logging AWS account activity.
- SNS Topic for Notifications: Create an SNS topic for alerts. Ensure relevant stakeholders are subscribed and have confirmed their subscriptions.

### Instructions

**Configure AWS CloudTrail**

Ensure CloudTrail is enabled and properly configured to log events in the AWS account.
CloudTrail logs should be directed to a specific log group in CloudWatch Logs.

In our specific case, a new Trail was created.
You need only specify the name, and KMS alias, the rest of the fields are fine to stay as defaults.

**Set Up SNS Topic for Alerts**

In the SNS console, create a new topic for CloudWatch Alerts.
Invite stakeholders to subscribe (via email, SMS, etc.).
The invited stakeholders will need to confirm their respective subscriptions in order for SNS to correctly send out notifications.

It is good practice to have separate Topics for differents kinds and types of alerts, so this could be something to improve on in future.

In our specific case, MSCV_CloudWatch_Alarms_Topic was created. You need only specify the name, and type of the topic, the rest are fine to stay as default values.

**Access CloudWatch Console**

1. Open CloudWatch from the management console and navigate to the Logs -> Log Groups section.

- NOTE: If there aren't any log groups created, refer back to CloudTrail and ensure the trail you have created has got the CloudWatch Logging enabled.

2. Select the log group you want to use. (in our case aws-cloudtrail-logs-393416225559-83ed3a78)

**Create Metric Filters for Key Events**

For each key event (e.g., Unauthorized API Calls, IAM Policy Changes), create a new metric filter

Click "Create metric filter."
Enter a filter pattern to match the specific event.
Assign a name (e.g., UnauthorizedAPICallsFilter), a metric namespace (e.g., CloudTrailMetrics), and a metric value (e.g. 1).

**Define Filter Patterns**

Use the below filters as a reference point, but it is worth noting that monitoring is an ever changing practice, so it is very important to regularly review these expressions and adjust depending on monitoring and alerting needs.

```
- UnauthorizedAPICalls = "{ ($.errorCode = "*UnauthorizedOperation" || $.errorCode = "AccessDenied*") && ($.userIdentity.userName != "nhsd_cloudhealth") }"
- IAMPolicyChanges = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"
- AWSConfigChange = "{($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder)||($.eventName=DeleteDeliveryChannel)||($.eventName=PutDeliveryChannel)||($.eventName=PutConfigurationRecorder))}"
- CMKPendingDeletionFilter = "{ $.eventSource = kms* && $.errorMessage = "* is pending deletion."}"
- CloudTrailChanges = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
- NACLChangeFilter = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = DeleteNetworkAcl) || ($.eventName = ReplaceNetworkAclAssociation) }"
- NetworkGatewayChangesFilter = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
- RouteTableChangeFilter = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRoute) || ($.eventName = DeleteRouteTable) }"
- SecurityGroupChangesFilter = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup)}"
- VPCChangeFilter = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) }"
```

**Create CloudWatch Alarms**

Then for each one of the filters created, create an alarm by selecting the metric filter and click "Create alarm."
Define the alarm condition (e.g., metric greater than 0 for 1 consecutive period).
Set alarm actions to notify via the SNS topic created earlier.

**Test Alarm Configuration**

The most realistic test for any montioring alert is a real life situation that actually triggers the defined expression.
However, it can also be tested by manually changing the state of the alert. This is not the best way since it can yield false positives, but for the purpose of testing SNS function, it can be useful.
You can do this using aws-cli:

```
aws cloudwatch set-alarm-state --alarm-name "UnauthorizedOperationCount" --state-reason "Testing alarm" --state-value ALARM
```

And then, remember to change the state back (it can also resolve itself automatically upon a re-check):

```
aws cloudwatch set-alarm-state --alarm-name "UnauthorizedOperationCount" --state-reason "Testing alarm" --state-value OK
```

### NOTES

The following sites contain some valuable examples that can be used for inspiration whenever ready to take the monitoring journey to the next level:

- https://asecure.cloud/l/cloudwatch/
- https://www.intelligentdiscovery.io/controls/cloudwatch/

## Server Access Logging on S3 Buckets

This is a feature provided by AWS. Server access logging for S3 buckets in AWS provides detailed records for the requests made to a specific bucket. These logs are invaluable for security and audit purposes.

### Enabling Server Access Logging

This can be done through the Management Console as well as the AWS CLI, but for the sake of convenience, we will only cover doing it though former.

Follow the instructions below:

1. Navigate to the AWS Management Console
2. Navigate to S3
3. Select the bucket you want to enable logging for.
4. Click the Properties tab.
5. Find Server access logging and click Edit.
6. Configure the destination where the logs will be written - using the same bucket for the server access logs is usually fine, unless the intention is to have many different objects in one bucket, in which case it would be a good idea to have separate buckets for each logical log group. In our case it is something like _s3://stackset-mavis-infrastruc-pipelinebuiltartifactbuc-navrlbfulzw6/server-access-logs/server-access-log_ - where _/server-access-logs/server-access-log_ are the destination folder and the log prefix.
7. Select the desired Log object key format. ('[DestinationPrefix][YYYY]-[MM]-[DD]-[hh]-[mm]-[ss]-[UniqueString]' should be fine, unless you plan to use these logs for analytics, in which case, choose the second option.)
8. Click Save Changes.

There is a delay in delivering the logs, so it can potentially take a couple hours before we start seeing some logs.

NOTE: When you enable server access logging, the S3 console automatically updates your bucket policy to include access to the S3 log delivery group.
