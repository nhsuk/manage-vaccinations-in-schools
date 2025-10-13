resource "aws_kms_key" "rds_cluster" {
  description = "Custom KMS key for new Aurora cluster"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccount"
        Effect = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::${var.account_id}:root"]
        }
        Action   = "kms:*"
        Resource = "*"
        }, {
        Sid    = "AllowBackupAccount"
        Effect = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::${var.backup_account_id}:root"]
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
          AWS = ["arn:aws:iam::${var.backup_account_id}:root"]
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

resource "aws_kms_key" "reporting_valkey" {
  description = "Custom KMS key for reporting elasticache cluster"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccount"
        Effect = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::${var.account_id}:root"]
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

