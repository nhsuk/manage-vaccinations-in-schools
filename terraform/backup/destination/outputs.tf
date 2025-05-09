output "destination_vault_arn" {
  description = "The ARN of the backup vault in the destination account is needed by the source account to copy backups into it."
  value       = module.destination.vault_arn
}
