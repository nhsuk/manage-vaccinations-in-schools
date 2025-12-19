terraform {
  required_version = "~> 1.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }
  }

  backend "s3" {
    bucket       = "mavisbackup-terraform-state"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

data "aws_caller_identity" "current" {}

locals {
  destination_account_id = data.aws_caller_identity.current.account_id
}

# We need a key for the backup vaults. This key will be used to encrypt the backups themselves.
# We need one per vault (on the assumption that each vault will be in a different account).
resource "aws_kms_key" "destination_backup_key" {
  description             = "Destination KMS key for AWS Backup vaults"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Sid    = "Enable IAM User Permissions"
        Principal = {
          AWS = "arn:aws:iam::${local.destination_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
        }, {
        Sid    = "AllowRestoreToSourceAccount"
        Effect = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::${var.source_account_id}:root"]
        }
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
        }, {
        Sid    = "Allow attachment of persistent resources"
        Effect = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::${var.source_account_id}:root"]
        }
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : "*",
        "Condition" : { "Bool" : { "kms:GrantIsForAWSResource" : true } }
      }
    ]
  })
}

module "destination" {
  source                        = "git@github.com:NHSDigital/terraform-aws-backup.git//modules/aws-backup-destination?ref=v1.1.0"
  source_account_name           = "mavis-${var.source_account_environment}"
  account_id                    = local.destination_account_id
  source_account_id             = var.source_account_id
  kms_key                       = aws_kms_key.destination_backup_key.arn
  enable_vault_protection       = true
  vault_lock_type               = "compliance"
  changeable_for_days           = 14
  vault_lock_min_retention_days = 7
}
