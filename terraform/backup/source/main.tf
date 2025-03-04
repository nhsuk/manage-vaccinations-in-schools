terraform {
  required_version = "~> 1.10.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87"
    }
  }

  backend "s3" {
    bucket         = "nhse-mavisbackup-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "mavisbackup-state-lock"
    encrypt = true
  }
}

provider  "aws" {
  region = "eu-west-2"
}

variable "destination_vault_arn" {
  description = "ARN of the backup vault in the destination account"
  type        = string
}

variable "environment" {
  description = "Environment name. Allowed values are 'dev' and 'prod'."
  type        = string
    validation {
        condition     = var.environment == "dev" || var.environment == "prod"
        error_message = "Environment must be either 'dev' or 'prod'."
    }
}

variable "terraform_role_arn" {
  description = "ARN of Terraform role used to deploy to account"
  type        = string
}

data "aws_arn" "destination_vault_arn" {
  arn = var.destination_vault_arn
}

data "aws_caller_identity" "current" {}

locals {
  # Adjust these as required
  project_name = "mavis-${var.environment}"
  source_account_id = data.aws_caller_identity.current.account_id
  destination_account_id = data.aws_arn.destination_vault_arn.account
}

# First, we create an S3 bucket for compliance reports. You may already have a module for creating
# S3 buckets with more refined access rules, which you may prefer to use.

resource "aws_s3_bucket" "backup_reports" {
  bucket_prefix        = "${local.project_name}-backup-reports"
}

# Now we have to configure access to the report bucket.

resource "aws_s3_bucket_ownership_controls" "backup_reports" {
  bucket = aws_s3_bucket.backup_reports.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "backup_reports" {
  depends_on = [aws_s3_bucket_ownership_controls.backup_reports]

  bucket = aws_s3_bucket.backup_reports.id
  acl    = "private"
}

# We need a key for the SNS topic that will be used for notifications from AWS Backup. This key
# will be used to encrypt the messages sent to the topic before they are sent to the subscribers,
# but isn't needed by the recipients of the messages.

# First we need some contextual data
# data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
        Action = "kms:*"
        Resource = "*"
      },
      {
        Effect    = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action    = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource  = "*"
      },
    ]
  })
}

# Now we can deploy the source and destination modules, referencing the resources we've created above.

module "source" {
  source = "../modules/aws-backup-source"

  backup_copy_vault_account_id       = local.destination_account_id
  backup_copy_vault_arn              = data.aws_arn.destination_vault_arn.arn
  environment_name                   = var.environment
  bootstrap_kms_key_arn              = aws_kms_key.backup_notifications.arn
  project_name                       = local.project_name
  reports_bucket                     = aws_s3_bucket.backup_reports.bucket
  terraform_role_arn                 = var.terraform_role_arn

  backup_plan_config                 = {
    "compliance_resource_types": [
      "S3"
    ],
    "rules": [
      {
        "copy_action": {
          "delete_after": 4
        },
        "lifecycle": {
          "delete_after": 2
        },
        "name": "daily_kept_for_2_days",
        "schedule": "cron(0 0 * * ? *)"
      }
    ],
    "selection_tag": "NHSE-Enable-Backup"
  }
  # Note here that we need to explicitly disable DynamoDB backups in the source account.
  # The default config in the module enables backups for all resource types.
  backup_plan_config_dynamodb =  {
    "compliance_resource_types": [
      "DynamoDB"
    ],
    "rules": [
    ],
    "enable": false,
    "selection_tag": "NHSE-Enable-Backup"
  }
}
