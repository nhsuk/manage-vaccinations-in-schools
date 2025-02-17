# Deployment Process

In order to take advantage of AWS's integrated CodeDeploy application supporting blue-green deployments we need to
implement a multi-stage deployment process. Deployment proceeds as follows

1. Update the Terraform configuration
   1. In most cases this will mean just updating the docker-image tag, which can be done with a command-line variable
      argument (e.g. without any file changes)
2. Apply terrafom configuration
   1. This should always happen in a two staged approach of using `terraform plan -out=<file_path>` and verifying the
      plan before calling `terraform apply <file_path>`
3. Copy the s3_uri variable that is generated as output from running terraform apply
4. Start a CodeDeploy deployment referencing the s3_uri as appspec.yaml file
