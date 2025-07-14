variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region"
}

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

variable "access_logs_bucket" {
  type        = string
  default     = "nhse-mavis-access-logs"
  description = "Name of the S3 bucket which stores access logs for various resources"
}

variable "account_id" {
  type        = string
  default     = "393416225559"
  description = "ID of aws account. Defaults to non-prod account."
  nullable    = false
}

variable "zone_name" {
  type        = string
  default     = "mavistesting.com"
  description = "Domain for which to create DNS certificate"
  nullable    = false
}

variable "http_hosts" {
  type = object({
    MAVIS__HOST                        = string
    MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = string
  })
  description = "Http host names. Only requests that set the HTTP Host Header to one of these values will be accepted."
  nullable    = true
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  description = "The name of the SSL Policy for the https listener"
  nullable    = false
}

locals {
  unique_host_headers = toset(values(var.http_hosts))
  host_headers        = tolist(local.unique_host_headers)
}

variable "dns_certificate_arn" {
  type        = list(string)
  description = "The ARN(s) for pre-existing DNS certificate(s) to be used for https listener"
}

locals {
  default_certificate_arn     = var.dns_certificate_arn == null ? module.dns_route53[0].certificate_arn : var.dns_certificate_arn[0]
  additional_sni_certificates = var.dns_certificate_arn == null ? [] : slice(var.dns_certificate_arn, 1, length(var.dns_certificate_arn))
}

variable "resource_name" {
  type = object(
    {
      rds_security_group       = string
      loadbalancer             = string
      lb_security_group        = string
      cloudwatch_vpc_log_group = string
    }
  )
  description = "Names of terraform managed resource. Used to import pre-existing infrastructure resources"
  nullable    = false
}

variable "ecs_log_retention_days" {
  type        = number
  default     = 30
  description = "Number of days to retain logs for ecs instances"
  nullable    = false
}
variable "vpc_log_retention_days" {
  type        = number
  default     = 14
  description = "Number of days to retain logs for the vpc traffic"
  nullable    = false
}

########## Task definition configuration ##########


variable "rails_master_key_path" {
  type        = string
  default     = "/mavis/development/credentials/RAILS_MASTER_KEY"
  description = "The path of the System Manager Parameter Store secure string for the rails master key."
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

locals {
  is_production = var.environment == "production"
  parameter_store_variables = tomap({ #TODO: Remove this once all variables are sourced from application config
    MAVIS__PDS__ENQUEUE_BULK_UPDATES                = "true"
    MAVIS__PDS__WAIT_BETWEEN_JOBS                   = 0.5
    MAVIS__ACADEMIC_YEAR_TODAY_OVERRIDE             = ""
    MAVIS__ACADEMIC_YEAR_NUMBER_OF_PREPARATION_DAYS = ""
    GOOD_JOB_MAX_THREADS                            = 5
  })
  parameter_store_arns = [for key, value in aws_ssm_parameter.environment_config : value.arn]

  task_envs = [
    {
      name  = "DB_HOST"
      value = aws_rds_cluster.core.endpoint
    },
    {
      name  = "DB_NAME"
      value = aws_rds_cluster.core.database_name
    },
    {
      name  = "MAVIS__HOST"
      value = var.http_hosts.MAVIS__HOST
    },
    {
      name  = "MAVIS__GIVE_OR_REFUSE_CONSENT_HOST"
      value = var.http_hosts.MAVIS__GIVE_OR_REFUSE_CONSENT_HOST
    }
  ]
  task_secrets = [
    {
      name      = "DB_CREDENTIALS"
      valueFrom = aws_rds_cluster.core.master_user_secret[0].secret_arn
    },
    {
      name      = "RAILS_MASTER_KEY"
      valueFrom = var.rails_master_key_path
    }
  ]
}

########## RDS configuration ##########

variable "backup_retention_period" {
  type        = number
  default     = 7
  description = "The number of days to retain backups for the RDS cluster."
}

variable "enable_backup_to_vault" {
  type        = bool
  default     = false
  description = "Enable backup to vault for the RDS cluster."
  nullable    = false
}

variable "backup_account_id" {
  type        = string
  default     = "904214613099"
  description = "The AWS account ID of the backup account"
  nullable    = false
}

locals {
  rds_cluster = "mavis-${var.environment}"
  db_instances = {
    "primary-1" = {
      promotion_tier = 1
    },
    "primary-2" = {
      promotion_tier = 1
    }
  }
}

########## ECS/Scaling Configuration ##########

variable "container_insights" {
  default     = "enabled"
  type        = string
  description = "Enable container insights level for the ECS cluster"
  nullable    = false
  validation {
    condition     = contains(["enhanced", "enabled", "disabled"], var.container_insights)
    error_message = "Valid values for container insights: enhanced, enabled, disabled"
  }
}

variable "minimum_web_replicas" {
  type        = number
  default     = 3
  description = "Minimum amount of allowed replicas for web service. Also the replica count when creating th service."
}

variable "maximum_web_replicas" {
  type        = number
  default     = 3
  description = "Maximum amount of allowed replicas for web service"
}

variable "good_job_replicas" {
  type        = number
  default     = 2
  description = "Amount of replicas for the good-job service"
}

variable "max_aurora_capacity_units" {
  type        = number
  default     = 8
  description = "Maximum amount of allowed ACU capacity for Aurora Serverless v2"
}

variable "active_lb_target_group" {
  type        = string
  description = "The actual loadbalancer target group is set by Codedeploy. However in scenarios where new resources behind the load balancer are created, terraform already needs to know the current target group. In this case, set the variable to the currently active target group."
  default     = "blue"
  validation {
    condition     = contains(["blue", "green"], var.active_lb_target_group)
    error_message = "Valid target groups: blue, green"
  }
}

locals {
  ecs_initial_lb_target_group = var.active_lb_target_group == "green" ? aws_lb_target_group.green.arn : aws_lb_target_group.blue.arn
  ecs_sg_ids                  = [module.web_service.security_group_id, module.good_job_service.security_group_id]
}
