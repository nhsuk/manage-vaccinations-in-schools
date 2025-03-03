resource "aws_backup_vault" "vault" {
  name        = "${var.source_account_name}-backup-vault"
  kms_key_arn = var.kms_key
}

output "vault_arn" {
  value = aws_backup_vault.vault.arn
}
