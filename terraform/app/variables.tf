variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region"
}

variable "environment_string" {
  type        = string
  description = "String literal for the environment"

  validation {
    condition = contains([
    "poc", "copilotmigration", "qa", "test", "training", "preview", "production"], var.environment_string)
    error_message = "Valid values for environment_string: mock, test."
  }
}

variable "account_id" {
  type        = string
  default     = "393416225559"
  description = "ID of aws account. Defaults to non-prod account."
}

variable "domain_name" {
  type        = string
  default     = "mavistesting.com"
  description = "Domain for which to create DNS certificate"
}

variable "dns_certificate_arn" {
  type        = string
  default     = ""
  description = "The ARN for a pre-existing DNS certificate to be used for ECS service"
}

variable "firewall_subnet_cidr" {
  type        = string
  description = "CIDR block for the firewall subnet"
  default     = "10.0.5.0/24"
}

variable "enable_firewall" {
  type        = bool
  default     = false
  description = "Boolean toggle to determine whether the firewall should be enabled."
}

variable "firewall_log_retention_days" {
  type        = number
  default     = 3
  description = "Number of days to retain logs for the firewall"
}


variable "resource_name" {
  type = object(
    {
      dbsubnet_group           = string
      db_cluster               = string
      rds_security_group       = string
      loadbalancer             = string
      lb_security_group        = string
      cloudwatch_vpc_log_group = string
    }
  )
  description = "Names of terraform managed resource. Used to import pre-existing infrastructure resources"
}

variable "ecs_log_retention_days" {
  type        = number
  default     = 7
  description = "Number of days to retain logs for ecs instances"
}
variable "vpc_log_retention_days" {
  type        = number
  default     = 7
  description = "Number of days to retain logs for the vpc traffic"
}

########## Task definition configuration ##########

variable "rails_env" {
  type        = string
  default     = "development"
  description = "The rails environment configuration to use for the mavis application"
  validation {
    condition     = contains(["development", "staging", "production"], var.rails_env)
    error_message = "Incorrect rails environment, allowed values are: {development, staging, production}"
  }
}

variable "rails_master_key_path" {
  type        = string
  default     = "/mavis/development/credentials/RAILS_MASTER_KEY"
  description = "The path of the System Manager Parameter Store secure string for the rails master key."
}

variable "container_name" {
  type        = string
  default     = "mavis"
  description = "Name of essential container in the task definition."
}

variable "docker_image" {
  type        = string
  default     = "<CHANGE_ME>"
  description = "The docker name for the essential container in the task definition."
}

variable "image_tag" {
  type        = string
  description = "The docker image tag for the essential container in the task definition."
}

locals {
  container_name = "${var.container_name}-${var.environment_string}"
  docker_image   = var.docker_image == "<CHANGE_ME>" ? "mavis-${var.environment_string}" : var.docker_image
  is_production  = var.environment_string == "production"
  dev_task_envs = [
    {
      name  = "DB_HOST"
      value = aws_rds_cluster.aurora_cluster.endpoint
    },
    {
      name  = "DB_NAME"
      value = aws_rds_cluster.aurora_cluster.database_name
    },
    {
      name  = "RAILS_ENV"
      value = var.rails_env
    }
  ]
  task_envs = concat(local.dev_task_envs, [
    {
      name  = "SENTRY_ENVIRONMENT"
      value = var.environment_string
    },
    {
      name  = "MAVIS__HOST"
      value = "${var.environment_string}.${var.domain_name}"
    },
    {
      name  = "MAVIS__GIVE_OR_REFUSE_CONSENT_HOST"
      value = "${var.environment_string}.${var.domain_name}"
    },
    {
      name  = "MAVIS__CIS2__ENABLED"
      value = "true"
    },
    {
      name  = "MAVIS__PDS__PERFORM_JOBS"
      value = "true"
    },
    {
      name  = "MAVIS__SPLUNK__ENABLED"
      value = "true"
    }
  ])
  task_secrets = [
    {
      name      = var.db_secret_arn == "" ? "DB_CREDENTIALS" : "DB_SECRET"
      valueFrom = var.db_secret_arn == "" ? aws_rds_cluster.aurora_cluster.master_user_secret[0].secret_arn : var.db_secret_arn
    },
    {
      name      = "RAILS_MASTER_KEY"
      valueFrom = var.rails_master_key_path
    }
  ]
}

########## RDS configuration ##########

variable "db_secret_arn" {
  type        = string
  description = "The ARN of the secret containing the DB credentials."
}

variable "backup_retention_period" {
  type = number
  default = 7
  description = "The number of days to retain backups for the RDS cluster."
}

########## ESC/Scaling Configuration ##########
variable "enable_autoscaling" {
  type        = bool
  default     = false
  description = "Boolean toggle to determine whether the ECS service should have autoscaling enabled."
}

variable "minimum_replicas" {
  type        = number
  default     = 2
  description = "Minimum amount of allowed replicas"
}

variable "maximum_replicas" {
  type        = number
  default     = 2
  description = "Maximum amount of allowed replicas"
}
