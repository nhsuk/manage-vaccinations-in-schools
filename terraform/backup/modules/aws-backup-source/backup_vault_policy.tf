resource "aws_backup_vault_policy" "vault_policy" {
  backup_vault_name = aws_backup_vault.main.name
  policy            = data.aws_iam_policy_document.vault_policy.json
}

data "aws_iam_policy_document" "vault_policy" {


  statement {
    sid    = "DenyApartFromTerraform"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnNotEquals"
      values   = [var.terraform_role_arn]
      variable = "aws:PrincipalArn"
    }

    actions = [
      "backup:DeleteRecoveryPoint",
      "backup:PutBackupVaultAccessPolicy",
      "backup:UpdateRecoveryPointLifecycle"
    ]

    resources = ["*"]
  }
  dynamic "statement" {
    for_each = var.backup_copy_vault_arn != "" && var.backup_copy_vault_account_id != "" ? [1] : []
    content {
      sid    = "Allow account to copy into backup vault"
      effect = "Allow"

      actions   = ["backup:CopyIntoBackupVault"]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.backup_copy_vault_account_id}:root"]
      }
    }
  }
}
