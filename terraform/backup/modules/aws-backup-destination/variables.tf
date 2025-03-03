variable "source_account_name" {
  # This is used as a prefix for the vault name, and referenced by the policy and the lock.
  # It doesn't have to match anything in the source AWS account.
  description = "The name of the account that backups will come from"
  type        = string
}

variable "source_account_id" {
  # The source account ID is used in the policy to allow permit root in the source account
  # to copy backups into the vault.
  description = "The id of the account that backups will come from"
  type        = string
}

variable "account_id" {
  # This is used to deny root from being able to copy backups from the vault
  # to anywhere other than the source account.  The constraint will need to
  # be removed if the original source account is lost.
  description = "The id of the account that the vault will be in"
  type        = string
}

variable "region" {
  description = "The region we should be operating in"
  type        = string
  default     = "eu-west-2"
}

variable "kms_key" {
  description = "The KMS key used to secure the vault"
  type        = string
}

variable "enable_vault_protection" {
  # With this set to true, privileges are locked down so that the vault can't be deleted or
  # have its policy changed. The minimum and maximum retention periods are also set only if this is true.
  description = "Flag which controls if the vault lock is enabled"
  type        = bool
  default     = false
}

variable "vault_lock_type" {
  description = "The type of lock that the vault should be, will default to governance"
  type        = string
  # See toplevel README.md:
  #   DO NOT SET THIS TO compliance UNTIL YOU ARE SURE THAT YOU WANT TO LOCK THE VAULT PERMANENTLY
  # When you do, you will also need to set "enable_vault_protection" to true for it to take effect.
  default     = "governance"
}

variable "vault_lock_min_retention_days" {
  description = "The minimum retention period that the vault retains its recovery points"
  type        = number
  default     = 365
}

variable "vault_lock_max_retention_days" {
  description = "The maximum retention period that the vault retains its recovery points"
  type        = number
  default     = 365
}

variable "changeable_for_days" {
  description = "How long you want the vault lock to be changeable for, only applies to compliance mode. This value is expressed in days no less than 3 and no greater than 36,500; otherwise, an error will return."
  type        = number
  default     = 14
}
