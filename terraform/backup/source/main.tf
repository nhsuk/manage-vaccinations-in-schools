terraform {
  required_version = "~> 1.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7.0"
    }
  }

  backend "s3" {
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

data "aws_caller_identity" "current" {}

data "aws_arn" "destination_vault" {
  arn = var.destination_vault_arn
}

locals {
  project_name           = "mavis-${var.environment}"
  source_account_id      = data.aws_caller_identity.current.account_id
  destination_account_id = data.aws_arn.destination_vault.account
  access_logs_suffix     = var.environment == "production" ? "-production" : ""
}

data "aws_s3_bucket" "mavis_logs" {
  bucket = "nhse-mavis-access-logs${local.access_logs_suffix}"
}

# First, we create an S3 bucket for compliance reports.
module "s3_reports_bucket" {
  source                   = "../../modules/s3"
  bucket_name              = "${local.project_name}-backup-reports"
  logging_target_bucket_id = data.aws_s3_bucket.mavis_logs.id
  logging_target_prefix    = "backup-reports/"
  additional_policy_statements = [
    {
      sid    = "AllowBackupReports"
      effect = "Allow"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${local.source_account_id}:role/aws-service-role/reports.backup.amazonaws.com/AWSServiceRoleForBackupReports"]
      }]
      actions   = ["s3:PutObject"]
      resources = ["arn:aws:s3:::${local.project_name}-backup-reports/*"]
      condition = {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    }
  ]
}

# Now we can define the key itself
resource "aws_kms_key" "backup_notifications" {
  description             = "KMS key for AWS Backup notifications"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Sid    = "Enable IAM User Permissions"
        Principal = {
          AWS = "arn:aws:iam::${local.source_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action   = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource = "*"
      },
    ]
  })
}

# Now we can deploy the source and destination modules, referencing the resources we've created above.

module "source" {
  source = "github.com/NHSDigital/terraform-aws-backup.git//modules/aws-backup-source?ref=v1.1.0"
  # Use SSH to fetch sources locally
  # source = "git@github.com:NHSDigital/terraform-aws-backup.git//modules/aws-backup-source?ref=v1.1.0"


  backup_copy_vault_account_id       = local.destination_account_id
  backup_copy_vault_arn              = var.destination_vault_arn
  environment_name                   = var.environment
  bootstrap_kms_key_arn              = aws_kms_key.backup_notifications.arn
  project_name                       = local.project_name
  reports_bucket                     = module.s3_reports_bucket.bucket_id
  terraform_role_arn                 = var.vault_owner_role_arn
  notifications_target_email_address = "thomas.leese1@nhs.net"
  backup_plan_config = {
    "compliance_resource_types" : [
      "Aurora"
    ],
    "rules" : [
      {
        "copy_action" : {
          "delete_after" : var.backup_retention_period
        },
        "lifecycle" : {
          "delete_after" : var.backup_retention_period
        },
        "name" : "${local.project_name}-backup-plan",
        "schedule" : "cron(0 7,19 * * ? *)"
      }
    ],
    "selection_tag" : "NHSE-Enable-Backup"
  }
  # Note here that we need to explicitly disable DynamoDB backups in the source account.
  # The default config in the module enables backups for all resource types.
  backup_plan_config_dynamodb = {
    "compliance_resource_types" : [
      "DynamoDB"
    ],
    "rules" : [
    ],
    "enable" : false,
    "selection_tag" : "NHSE-Enable-Backup"
  }
}
