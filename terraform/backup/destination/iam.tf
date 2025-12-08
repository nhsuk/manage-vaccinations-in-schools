resource "aws_iam_policy" "restore" {
  name        = "RestoreBackup-${var.source_account_environment}"
  description = "Allows listing and copying of AWS Backup recovery points"
  policy      = data.aws_iam_policy_document.restore.json
}

data "aws_iam_policy_document" "restore" {
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