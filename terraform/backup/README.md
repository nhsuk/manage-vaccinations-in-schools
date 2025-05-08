# Backups

This directory contains the Terraform configuration for the backup infrastructure. It uses the Terraform module
provided by NHSDigital in https://github.com/NHSDigital/terraform-aws-backup.

## Usage

The `source` directory contains the configuration to be applied in the main AWS account where the app is running.
It is set up with the `terraform-backup-module.yml` GitHub Action workflow.

The `destination` directory contains the configuration to be applied in a different AWS account that stores the backup of the backup.
It will rarely change. In case of changes, terraform needs to be run manually.

To set up the backup infrastructure from scratch, follow these steps:

1. Bootstrap the destination backup account by running `terraform apply` in the `destination-bootstrap` directory. This will create an S3 bucket and a DynamoDB table for the Terraform state.
2. Set up the **destination** account by running `terraform apply` in the `destination` directory. Pass the account_id of the source account as input.
   It returns the ARN of the destination vault that is created.
3. Put the ARN of the destination vault in the \*.tfvars file in the `source` directory.
4. Create an AWS policy based on the `aws-backup-policy.json` file.
   This policy should be attached to the IAM role that is used by the `terraform-backup-module.yml` GitHub Action workflow.
5. Set up the **source** account by running the `terraform-backup-module.yml` GitHub Action workflow.

## Disaster Recovery

To restore the database from a recovery point, follow these steps:

1. In the AWS Backup vault, select the recovery point you want to restore.
2. Set a new DB cluster identifier, e.g. `mavis-$ENV-restored` and click on "Restore".
3. Wait for the restored DB cluster to be complete.
4. Update the DB credentials:
   - If the environment uses self managed credentials, update the DB hostname and instance name in the secret in AWS Secrets Manager.
   - If the environment uses RDS managed credentials, it's likely that the credentials are also gone. In that case,
     - Update the DB cluster config in the UI to use RDS-managed credentials again.
5. Refresh the terraform state of the app by running `terraform refresh`.
6. Import the new DB cluster into the terraform state

```
terraform import aws_rds_cluster.aurora_cluster mavis-$ENV-restored
```

6. Run `terraform apply`. This will create a new DB instance and update all security groups as necessary.
7. Restart any running ECS tasks.
