resource "aws_kms_key" "aws_backup_key" {
  description             = "AWS Backup KMS Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.backup_key_policy.json
}

resource "aws_kms_alias" "backup_key" {
  name          = "alias/${var.environment_name}/backup-key"
  target_key_id = aws_kms_key.aws_backup_key.key_id
}

data "aws_iam_policy_document" "backup_key_policy" {
  #checkov:skip=CKV_AWS_109:See (CERSS-25168) for more info
  #checkov:skip=CKV_AWS_111:See (CERSS-25169) for more info
  statement {
    sid = "AllowBackupUseOfKey"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey", "kms:Decrypt", "kms:Encrypt"]
    resources = ["*"]
  }
  statement {
    sid = "EnableIAMUserPermissions"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", data.aws_caller_identity.current.arn]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}
