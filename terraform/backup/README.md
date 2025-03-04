# Backups

This directory contains the Terraform configuration for the backup infrastructure. It uses the Terraform modules 
provided by NHSDigital in https://github.com/NHSDigital/terraform-aws-backup.

## Usage

The `source` directory contains the configuration to be applied in the main AWS account where the app is running.
The `destination` directory contains the configuration to be applied in a different AWS account that stores the backup of the backup.
For now, both configurations are to be applied manually by running `terraform apply` in the respective directory. In the future,
this should happen via a dedicated GitHub Actions workflow. 

To set up the backup infrastructure from scratch, follow these steps:
1) Create an S3 bucket "nhse-mavisbackup-destination-terraform-state" and a DynamoDB table "mavisbackup-destination-state-lock" in the **destination** account (for Terraform).
2) Create an S3 bucket "nhse-mavisbackup-terraform-state" and a DynamoDB table "mavisbackup-state-lock" in the **source** account (for Terraform).
3) Set up the **destination** account by running `terraform apply` in the `destination` directory. Pass the account_id of the source account as input.
   It returns the ARN of the destination vault that is created.
4) Put the ARN of the destination vault in the *.tfvars file in the `source` directory.
5) Set up the **source** account by running `terraform apply -var-file=dev.tfvars` in the `source` directory.
