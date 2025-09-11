variable "environment" {
  type        = string
  description = "Environment name"
  nullable    = false
  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "Valid values for environment: development, production."
  }
}

variable "account_id" {
  type        = number
  description = "AWS account ID"
  nullable    = false
}

variable "sso_group_ids" {
  type        = map(map(string))
  description = "Map of SSO group names to their IDs"
  default     = {}
  nullable    = false
}

locals {
  group_ids = {
    ADMIN = {
      AWS-Mavis-Admins = "96f2a2a4-3031-70a2-01be-db6c0030cb03"
    }
    EDITOR = {
      AWS-Mavis-Developers            = "f68222d4-c0b1-700b-b09f-81572d4dee95"
      AWS-Mavis-DataReplicationAccess = "46b21234-40e1-7071-1325-1a564e8a1ad4"
    }
    VIEWER = {
      AWS-Mavis-ReadOnly = "16b29214-60a1-7008-ff52-0ccd29b7e2d4"
    }
  }
  bucket_name             = "nhse-mavis-grafana-${var.environment}"
  prefix_environment      = var.environment == "development" ? "qa" : var.environment
  data_replication_prefix = "mavis-${local.prefix_environment}-data-replication"
}
