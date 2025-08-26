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

variable "appspec_bucket" {
  type        = string
  description = "Name of the S3 bucket which stores appspec files"
  nullable    = false
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

variable "enable_cis2" {
  type        = bool
  default     = true
  description = "Boolean toggle to determine whether the CIS2 feature should be enabled."
  nullable    = false
}

variable "enable_pds_enqueue_bulk_updates" {
  type        = bool
  default     = true
  description = "Whether PDS jobs that update patients in bulk should execute or not. This is disabled in non-production environments to avoid making unnecessary requests to PDS."
  nullable    = false
}

variable "academic_year_today_override" {
  type        = string
  default     = "nil"
  description = "A date that can be used to override today's date when calculating the current academic year."
  nullable    = false
}

variable "academic_year_number_of_preparation_days" {
  type        = number
  default     = 31
  description = "How many days before the start of the academic year to start the preparation period."
  nullable    = false
}

variable "pds_rate_limit_per_second" {
  type        = number
  default     = 5
  description = "The rate limit when communicating with PDS."
  nullable    = false
}

variable "enable_splunk" {
  type        = bool
  default     = true
  description = "Boolean toggle to determine whether the Splunk feature should be enabled."
  nullable    = false
}

variable "enable_enhanced_db_monitoring" {
  type        = bool
  default     = false
  description = "Boolean toggle to determine whether enhanced DB monitoring should be enabled."
  nullable    = false
}

variable "app_version" {
  type        = string
  description = "The version identifier for the MAVIS application deployment"
  default     = "Unknown"
  nullable    = false
}

locals {
  is_production = var.environment == "production"
  parameter_store_variables = tomap({
    MAVIS__ACADEMIC_YEAR_TODAY_OVERRIDE             = var.academic_year_today_override
    MAVIS__ACADEMIC_YEAR_NUMBER_OF_PREPARATION_DAYS = var.academic_year_number_of_preparation_days
    MAVIS__PDS__ENQUEUE_BULK_UPDATES                = var.enable_pds_enqueue_bulk_updates ? "true" : "false"
    MAVIS__PDS__RATE_LIMIT_PER_SECOND               = var.pds_rate_limit_per_second
    GOOD_JOB_MAX_THREADS                            = 5
    SIDEKIQ_CONCURRENCY                             = 5
  })
  parameter_store_config_list = [for key, value in local.parameter_store_variables : {
    name      = key
    valueFrom = aws_ssm_parameter.environment_config[key].arn
  }]
  parameter_store_arns = [for key, value in local.parameter_store_variables : aws_ssm_parameter.environment_config[key].arn]

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
      name  = "RAILS_ENV"
      value = var.rails_env
    },
    {
      name  = "SENTRY_ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "MAVIS__HOST"
      value = var.http_hosts.MAVIS__HOST
    },
    {
      name  = "MAVIS__GIVE_OR_REFUSE_CONSENT_HOST"
      value = var.http_hosts.MAVIS__GIVE_OR_REFUSE_CONSENT_HOST
    },
    {
      name  = "MAVIS__CIS2__ENABLED"
      value = var.enable_cis2 ? "true" : "false"
    },
    {
      name  = "MAVIS__SPLUNK__ENABLED"
      value = var.enable_splunk ? "true" : "false"
    },
    {
      name  = "APP_VERSION"
      value = var.app_version
    },
    {
      name  = "SIDEKIQ_REDIS_URL"
      value = "rediss://${aws_elasticache_replication_group.valkey.primary_endpoint_address}:${var.valkey_port}"
    },
  ]
  task_secrets = concat([
    {
      name      = "DB_CREDENTIALS"
      valueFrom = aws_rds_cluster.core.master_user_secret[0].secret_arn
    },
    {
      name      = "RAILS_MASTER_KEY"
      valueFrom = var.rails_master_key_path
    }
  ], local.parameter_store_config_list)
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
  default     = 2
  description = "Minimum amount of allowed replicas for web service. Also the replica count when creating th service."
}

variable "maximum_web_replicas" {
  type        = number
  default     = 4
  description = "Maximum amount of allowed replicas for web service"
}

variable "good_job_replicas" {
  type        = number
  default     = 2
  description = "Amount of replicas for the good-job service"
}

variable "minimum_sidekiq_replicas" {
  type        = number
  default     = 2
  description = "Amount of replicas for the sidekiq service"
}

variable "maximum_sidekiq_replicas" {
  type        = number
  default     = 4
  description = "Amount of replicas for the sidekiq service"
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

########## Valkey Configuration ##########

variable "valkey_port" {
  type        = number
  default     = 6379
  description = "Port number for Valkey cluster"
  nullable    = false
  validation {
    condition     = var.valkey_port > 0 && var.valkey_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "valkey_engine_version" {
  type        = string
  default     = "8.0"
  description = "Valkey engine version"
  nullable    = false
}

variable "valkey_node_type" {
  type        = string
  default     = "cache.m7g.large"
  description = "ElastiCache node type for Valkey (use cache.t3.micro for sandbox, cache.m7g.large+ for production)"
  nullable    = false
}

variable "valkey_failover_enabled" {
  type        = bool
  default     = true
  description = "Enable automatic failover for Valkey cluster"
  nullable    = false
}

variable "valkey_snapshot_retention_limit" {
  type        = number
  default     = 7
  description = "Number of days to retain Valkey snapshots"
  nullable    = false
  validation {
    condition     = var.valkey_snapshot_retention_limit >= 0 && var.valkey_snapshot_retention_limit <= 35
    error_message = "Snapshot retention must be between 0 and 35 days."
  }
}

variable "valkey_snapshot_window" {
  type        = string
  default     = "00:00-02:00"
  description = "Daily snapshot window for Valkey (HH:MM-HH:MM format, UTC)"
  nullable    = false
}

variable "valkey_maintenance_window" {
  type        = string
  default     = "sun:02:00-sun:04:00"
  description = "Weekly maintenance window for Valkey (ddd:HH:MM-ddd:HH:MM format, UTC)"
  nullable    = false
}

variable "valkey_log_retention_days" {
  type        = number
  default     = 14
  description = "Number of days to retain Valkey logs (minimum 3 for sandbox, 14+ for production)"
  nullable    = false
  validation {
    condition     = var.valkey_log_retention_days >= 1 && var.valkey_log_retention_days <= 365
    error_message = "Log retention must be between 1 and 365 days."
  }
}

locals {
  ecs_initial_lb_target_group     = var.active_lb_target_group == "green" ? aws_lb_target_group.green.arn : aws_lb_target_group.blue.arn
  ecs_sg_ids                      = [module.web_service.security_group_id, module.good_job_service.security_group_id, module.sidekiq_service.security_group_id]
  valkey_cache_availability_zones = var.valkey_failover_enabled ? [aws_subnet.private_subnet_a.availability_zone, aws_subnet.private_subnet_b.availability_zone] : [aws_subnet.private_subnet_a.availability_zone]
}
