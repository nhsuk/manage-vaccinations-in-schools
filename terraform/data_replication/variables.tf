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

variable "db_secret_arn" {
  type        = string
  description = "The ARN of the secret that stores the credentials for the database from which the snapshot originates."
  nullable    = false
}

variable "account_id" {
  type        = string
  default     = "393416225559"
  description = "ID of aws account. Defaults to non-prod account."
  nullable    = false
}

variable "docker_image" {
  type        = string
  default     = "mavis/webapp"
  description = "The docker image name for the essential container in the task definition"
  nullable    = false
}

variable "image_digest" {
  type        = string
  description = "The docker image digest for the essential container in the task definition."
  nullable    = false
}

variable "rails_env" {
  type        = string
  default     = "staging"
  description = "The rails environment configuration to use for the mavis application"
  nullable    = false
  validation {
    condition     = contains(["staging", "production"], var.rails_env)
    error_message = "Incorrect rails environment, allowed values are: {staging, production}"
  }
}

variable "rails_master_key_path" {
  type        = string
  default     = "/mavis/staging/credentials/RAILS_MASTER_KEY"
  description = "The path of the System Manager Parameter Store secure string for the rails master key."
  nullable    = false
}

locals {
  name_prefix = "mavis-${var.environment}-data-replication"
  subnet_list = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

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
      value = var.rails_env
    },
    {
      name  = "SENTRY_ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "MAVIS__CIS2__ENABLED"
      value = "false"
    },
    {
      name  = "MAVIS__SPLUNK__ENABLED"
      value = "false"
    },
    {
      name  = "MAVIS__PDS__ENQUEUE_BULK_UPDATES"
      value = "false"
    }
  ]
  task_secrets = [
    {
      name      = "DB_CREDENTIALS"
      valueFrom = var.db_secret_arn
    },
    {
      name      = "RAILS_MASTER_KEY"
      valueFrom = var.rails_master_key_path
    },
    {
      name      = "READ_ONLY_DB_PASSWORD"
      valueFrom = aws_secretsmanager_secret.ro_db_password.arn
    }
  ]
}

variable "allowed_egress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for the allowed outbound traffic from the data replication service."
  default     = []
}
