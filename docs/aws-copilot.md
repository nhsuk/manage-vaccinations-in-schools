# Provisioning a new environment using AWS Copilot

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

## Tailing logs of running service

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
$ copilot env init --import cert arn:aws.....
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
$ copilot env deploy --name pentest
```

Open `copilot/webapp/manifest.yml` and add a new section to the `environments`:

```diff
environments:
  staging:
    variables:
      RAILS_ENV: staging
      RCVAPP__SUPPORT_USERNAME: manage
      RCVAPP__SUPPORT_PASSWORD: vaccinations
+    http:
+      alias:
+        - "pentest.manage-vaccinations-in-schools.nhs.uk"
+        - "pentest.give-or-refuse-consent-for-vaccinations.nhs.uk"
+  pentest:
+    variables:
+      RAILS_ENV: staging
+      RCVAPP__SUPPORT_USERNAME: manage
+      RCVAPP__SUPPORT_PASSWORD: vaccinations
```

You'll then need to set up the secrets. Check the `secrets` section of the
`webapp/manifest.yml`. Set up each one with:

```bash
$ copilot secret init
```

Skip the environments you're not setting up keys for by hitting return.

Finally, deploy the app:

```bash
$ copilot svc deploy --env pentest
```

When you're done with the environment, you can tear it down with:

```bash
$ copilot svc delete --name pentest
$ copilot env delete --name pentest
```
