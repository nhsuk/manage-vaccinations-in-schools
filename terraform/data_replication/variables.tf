variable "environment" {
  type        = string
  description = "String literal for the environment"
  nullable    = false

  validation {
    condition = contains([
      "sandbox-alpha", "sandbox-beta", "qa", "test", "training", "preview", "production"
    ], var.environment)
    error_message = "Valid values for environment: sandbox-alpha, sandbox-beta, qa, test, training, preview, production."
  }
}

variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region"
  nullable    = false
}

variable "db_engine_version" {
  type        = string
  default     = "16.8"
  description = "The version of the database engine to use."
  nullable    = false
}

variable "imported_snapshot" {
  type        = string
  description = "ARN of snapshot to create DB cluster from. This is the basis for replicating the existing DB."
  nullable    = false
}

variable "max_aurora_capacity_units" {
  type        = number
  default     = 8
  description = "Maximum amount of allowed ACU capacity for Aurora Serverless v2"
}

variable "account_id" {
  type        = string
  default     = "393416225559"
  description = "ID of aws account. Defaults to non-prod account."
  nullable    = false
}

variable "rails_master_key_path" {
  type        = string
  default     = "/mavis/staging/credentials/RAILS_MASTER_KEY"
  description = "The path of the System Manager Parameter Store secure string for the rails master key."
  nullable    = false
}

locals {
  name_prefix                        = "mavis-${var.environment}-data-replication"
  subnet_list                        = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  shared_egress_infrastructure_count = min(length(var.allowed_egress_cidr_blocks), 1)

  task_envs = [
    {
      name  = "DB_HOST"
      value = aws_rds_cluster.cluster.endpoint
    },
    {
      name  = "DB_NAME"
      value = aws_rds_cluster.cluster.database_name
    },
    {
      name  = "RAILS_ENV"
      value = var.environment == "production" ? "production" : "staging"
    },
    {
      name  = "REDIS_CACHE_URL"
      value = "not_needed"
    }
  ]
  task_secrets = [
    {
      name      = "DB_CREDENTIALS"
      valueFrom = aws_rds_cluster.cluster.master_user_secret[0].secret_arn
    },
    {
      name      = "RAILS_MASTER_KEY"
      valueFrom = var.rails_master_key_path
    }
  ]
}

variable "allowed_egress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for the allowed outbound traffic from the data replication service."
  default     = []
}
