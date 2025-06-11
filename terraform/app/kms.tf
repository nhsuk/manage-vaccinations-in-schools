data "aws_iam_role" "dms_service_linked_role" {
  name = "AWSServiceRoleForDMSServerless"
}

resource "aws_kms_key" "rds_cluster" {
  description = "Custom KMS key for new Aurora cluster"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccount"
        Effect = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::${var.account_id}:root", "arn:aws:iam::${var.backup_account_id}:root"]
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowDMS"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_iam_role.dms_service_linked_role.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}
