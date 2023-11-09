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

```bash
$ copilot env init
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
$ copilot svc deploy --env throwaway
```

When you're done with the environment, you can tear it down with:

```bash
$ copilot svc delete --name pentest
$ copilot env delete --name pentest
```
