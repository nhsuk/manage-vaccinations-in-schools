variable "environment" {
  type        = string
  description = "Environment name"
  nullable    = false
  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "Valid values for environment: development, production."
  }
}
locals {
  group_ids = {
    AWS-Mavis-Admins     = "96f2a2a4-3031-70a2-01be-db6c0030cb03"
    AWS-Mavis-Developers = "f68222d4-c0b1-700b-b09f-81572d4dee95"
    AWS-Mavis-ReadOnly   = "16b29214-60a1-7008-ff52-0ccd29b7e2d4"
  }
}
