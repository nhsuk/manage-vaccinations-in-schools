resource "aws_iam_role" "terraform_apply_role" {
  name = "MavisBackupSourceAccountTerraformRole"
  description = "The role that terraform will assume to apply changes"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::393416225559:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_Admin_a5c68b9cfd6e5cdd"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "source_account_backup_permissions" {
  name = "mavisbackup-source-account-permissions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "backup:ListBackupPlans",
          "backup:CreateBackupPlan",
          "backup:DeleteBackupPlan",
          "backup:DescribeBackupPlan",
          "backup:UpdateBackupPlan",
          "backup:GetBackupPlan",
          "backup:CreateReportPlan",
          "backup:DeleteReportPlan",
          "backup:DescribeReportPlan",
          "backup:UpdateReportPlan",
          "backup:ListReportPlans",
          "backup:TagResource",
          "backup:ListTags",
          "backup:CreateFramework",
          "backup:DeleteFramework",
          "backup:DescribeFramework",
          "backup:ListFrameworks",
          "backup:CreateBackupVault",
          "backup:DeleteBackupVault",
          "backup:DescribeBackupVault",
          "backup:ListBackupVaults",
          "backup:PutBackupVaultAccessPolicy",
          "backup:GetBackupVaultAccessPolicy",
          "backup:CreateBackupSelection",
          "backup:GetBackupSelection",
          "backup:DeleteBackupSelection",
          "backup:CreateRestoreTestingPlan",
          "backup:DeleteRestoreTestingPlan",
          "backup:GetRestoreTestingPlan",
          "backup:ListRestoreTestingPlans",
          "backup:UpdateRestoreTestingPlan"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "backup-storage:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:ListKeys",
          "kms:DescribeKey",
          "kms:DeleteKey",
          "kms:CreateKey",
          "kms:ListAliases",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:TagResource"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "source_account_backup_permissions" {
  policy_arn = aws_iam_policy.source_account_backup_permissions.arn
  role = aws_iam_role.terraform_apply_role.name
}

output "terraform_role_arn" {
  value = aws_iam_role.terraform_apply_role.arn
}
