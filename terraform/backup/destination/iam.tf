resource "aws_iam_policy" "backup_manager" {
  name        = "BackupManager-${var.source_account_environment}"
  description = "Allows listing and copying of AWS Backup recovery points"
  policy      = data.aws_iam_policy_document.backup_manager.json
}

data "aws_iam_policy_document" "backup_manager" {
  statement {
    sid    = "RecoveryPoints"
    effect = "Allow"

    actions = [
      "backup:DescribeRecoveryPoint",
      "backup:DescribeBackupVault",
      "backup:TagResource",
      "backup:UntagResource",
      "backup:ListTags"
    ]
    resources = [
      "arn:aws:backup:eu-west-2:${data.aws_caller_identity.current.account_id}:backup-vault:mavis-${var.source_account_environment}-backup-vault",
      "arn:aws:backup:eu-west-2:${data.aws_caller_identity.current.account_id}:recovery-point:nhs-*-eu-west-2-pars-main-*"
    ]
  }

  statement {
    sid    = "BackupVault"
    effect = "Allow"

    actions = [
      "backup:ListBackupVaults",
      "backup:ListRecoveryPointsByBackupVault",
      "backup:StartCopyJob",
      "backup:ListCopyJobs",
      "backup:DescribeCopyJob"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ListRoles"
    effect = "Allow"

    actions   = ["iam:ListRoles"]
    resources = ["*"]
  }

  statement {
    sid    = "PassRole"
    effect = "Allow"

    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::904214613099:role/service-role/AWSBackupDefaultServiceRole"]
  }
}

resource "aws_iam_policy" "backup_admin" {
  count       = var.source_account_environment == "production" ? 1 : 0
  name        = "BackupAdmin"
  description = "Allows updating backup plans"
  policy      = data.aws_iam_policy_document.backup_admin.json
}


data "aws_iam_policy_document" "backup_admin" {
  statement {
    sid    = "AllowBackupAdministration"
    effect = "Allow"

    actions = [
      "backup:CreateBackupPlan",
      "backup:CreateBackupVault",
      "backup:StartBackupJob",
      "backup:ListBackupPlans",
      "backup:ListBackupVaults",
      "backup:ListRecoveryPointsByBackupVault"
    ]
    resources = ["*"]
  }
}