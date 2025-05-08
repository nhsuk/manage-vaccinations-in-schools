variable "destination_vault_arn" {
  description = "ARN of the backup vault in the destination account"
  type        = string
}

variable "environment" {
  description = "Environment name (AWS Account level)."
  type        = string
}

variable "vault_owner_role_arn" {
  description = "ARN of the role that can delete backups"
  type        = string
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
}
