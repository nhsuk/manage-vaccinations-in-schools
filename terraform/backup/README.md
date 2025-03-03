# Backups

This directory contains the Terraform configuration for the backup infrastructure. It uses the Terraform modules 
provided by NHSDigital in https://github.com/NHSDigital/terraform-aws-backup.

## Usage

The `source` directory contains the configuration to be applied in the main AWS account where the app is running.
The `destination` directory contains the configuration to be applied in a different AWS account that stores the backup of the backup.
For now, both configurations are to be applied manually by running `terraform apply` in the respective directory. In the future,
this should happen via a dedicated GitHub Actions workflow. 

First, set up the destination account and pass the account_id of the source account as input. It returns the ARN of
the vault that is created.
Next, set up the source account and pass the ARN of the vault as input.
