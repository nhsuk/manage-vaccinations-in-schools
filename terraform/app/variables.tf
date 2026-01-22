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
      "sandbox-alpha", "sandbox-beta", "qa", "performance", "test", "training", "preview", "pentest", "production"
    ], var.environment)
    error_message = "Valid values for environment: sandbox-alpha, sandbox-beta, qa, performance, test, training, preview, production."
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

variable "mise_sops_age_key_path" {
  type        = string
  default     = "/mavis/development/credentials/MISE_SOPS_AGE_KEY"
  description = "The path of the System Manager Parameter Store secure string for the MISE SOPS age key."
  nullable    = false
}

########## Task definition configuration ##########


variable "rails_master_key_path" {
  type        = string
  default     = "/mavis/development/credentials/RAILS_MASTER_KEY"
  description = "The path of the System Manager Parameter Store secure string for the rails master key."
  nullable    = false
}

variable "enable_enhanced_db_monitoring" {
  type        = bool
  default     = false
  description = "Boolean toggle to determine whether enhanced DB monitoring should be enabled."
  nullable    = false
}

locals {
  server_types  = toset(["CORE", "REPORTING"])
  is_production = var.environment == "production"
  parameter_store_variables = tomap({
    CORE = local.is_production ? {} : tomap({
      MAVIS__CIS2__ENABLED                            = "CHANGE_ME"
      MAVIS__SPLUNK__ENABLED                          = "CHANGE_ME"
      MAVIS__ACADEMIC_YEAR_TODAY_OVERRIDE             = "CHANGE_ME"
      MAVIS__ACADEMIC_YEAR_NUMBER_OF_PREPARATION_DAYS = "CHANGE_ME"
      MAVIS__PDS__ENQUEUE_BULK_UPDATES                = "CHANGE_ME"
      MAVIS__PDS__RATE_LIMIT_PER_SECOND               = "CHANGE_ME"
    })
    REPORTING = local.is_production ? {} : tomap({
    })
  })
  applications_accessing_secrets_or_parameters = toset([
    for server_type in local.server_types : server_type if length(local.task_secrets[server_type]) > 0
  ])

  redis_cache_url   = "rediss://${aws_elasticache_serverless_cache.rails_cache.endpoint[0].address}:${aws_elasticache_serverless_cache.rails_cache.endpoint[0].port}"
  redis_sidekiq_url = "rediss://${aws_elasticache_replication_group.valkey.primary_endpoint_address}:${var.valkey_port}"

  secret_values = tomap(
    {
      CORE = [{
        name      = "DB_CREDENTIALS"
        valueFrom = aws_rds_cluster.core.master_user_secret[0].secret_arn
      }]
      REPORTING = []
    }
  )

  parameter_values = tomap(
    {
      CORE = concat(
        [for key, value in aws_ssm_parameter.core_environment_overwrites :
          {
            name      = key
            valueFrom = "arn:aws:ssm:${var.region}:${var.account_id}:parameter${value.name}"
          }
        ],
        [{
          name      = "RAILS_MASTER_KEY"
          valueFrom = "arn:aws:ssm:${var.region}:${var.account_id}:parameter${var.rails_master_key_path}"
        }],
      )
      REPORTING = concat(
        [for key, value in aws_ssm_parameter.reporting_environment_overwrites :
          {
            name      = key
            valueFrom = "arn:aws:ssm:${var.region}:${var.account_id}:parameter${value.name}"
          }
        ],
        [{
          name      = "MISE_SOPS_AGE_KEY"
          valueFrom = "arn:aws:ssm:${var.region}:${var.account_id}:parameter${var.mise_sops_age_key_path}"
        }],
      )
    }
  )

  sandbox_envs = (
    startswith(var.environment, "sandbox") ? [
      {
        name  = "SENTRY_DISABLE"
        value = "true"
      }
    ] : []
  )

  task_envs = {
    CORE = concat([
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
      },
      {
        name  = "SIDEKIQ_REDIS_URL"
        value = local.redis_sidekiq_url
      },
      {
        name  = "REDIS_CACHE_URL"
        value = local.redis_cache_url
      },
      {
        name  = "RAILS_ENV"
        value = var.environment == "production" ? "production" : "staging"
      },
      {
        name  = "RAILS_MAX_THREADS"
        value = 5
      },
      {
        name  = "SENTRY_ENVIRONMENT"
        value = var.environment
      },
      ], local.sandbox_envs,
    )

    REPORTING = [
      {
        name  = "VALKEY_ADDRESS"
        value = aws_elasticache_serverless_cache.reporting_service.endpoint[0].address
      },
      {
        name  = "VALKEY_PORT"
        value = aws_elasticache_serverless_cache.reporting_service.endpoint[0].port
      },
      {
        name  = "ROOT_URL"
        value = "https://${var.http_hosts.MAVIS__HOST}/reports/"
      },
      {
        name  = "MISE_ENV"
        value = var.environment == "production" ? "production" : "staging"
      },
      {
        name  = "SENTRY_ENVIRONMENT"
        value = var.environment
      }
    ]
  }

  export_prometheus_metrics = contains([
    "performance", "production"
  ], var.environment)

  sidekiq_envs = concat(
    local.task_envs["CORE"],
    [
      {
        name  = "EXPORT_SIDEKIQ_METRICS"
        value = tostring(local.export_prometheus_metrics)
      }
    ]
  )

  web_envs = concat(
    local.task_envs["CORE"],
    [
      {
        name  = "EXPORT_PUMA_METRICS"
        value = tostring(local.export_prometheus_metrics)
      }
    ]
  )

  task_secrets = {
    CORE      = concat(local.secret_values["CORE"], local.parameter_values["CORE"])
    REPORTING = concat(local.secret_values["REPORTING"], local.parameter_values["REPORTING"])
  }
  container_ports = {
    web       = 4000
    sidekiq   = 4000
    reporting = 5000
  }
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

variable "minimum_sidekiq_replicas" {
  type        = number
  default     = 2
  description = "Amount of replicas for the sidekiq service"
}

variable "maximum_sidekiq_replicas" {
  type        = number
  default     = 12
  description = "Amount of replicas for the sidekiq service"
}

variable "minimum_reporting_replicas" {
  type        = number
  default     = 0
  description = "Minimum amount of allowed replicas for reporting service. Also the replica count when creating the service."
}

variable "maximum_reporting_replicas" {
  type        = number
  default     = 0
  description = "Maximum amount of allowed replicas for reporting service"
}

variable "enable_ops_service" {
  type        = bool
  default     = false
  description = "Number of replicas for the ops service"
  nullable    = false
}


variable "max_aurora_capacity_units" {
  type        = number
  default     = 8
  description = "Maximum amount of allowed ACU capacity for Aurora Serverless v2"
}

variable "reporting_endpoints" {
  type        = list(string)
  description = "List of endpoints for the loadbalancer to forward to the reporting service"
  default     = ["/reports", "/reports/*"]
  nullable    = false
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

variable "waf_rule_actions" {
  type = map(string)
  default = {
    core_rule_set      = "COUNT"
    known_bad_inputs   = "COUNT"
    ip_reputation_list = "COUNT"
    rate_limiting      = "COUNT"
  }
  description = "Map of WAF rule actions (COUNT/BLOCK)"
  validation {
    condition = alltrue([
      for action in values(var.waf_rule_actions) : contains(["COUNT", "BLOCK"], action)
    ])
    error_message = "Valid values: COUNT or BLOCK"
  }
}

variable "waf_logging_enabled" {
  type        = bool
  default     = true
  description = "Enable WAF request logging"
  nullable    = false
}

variable "waf_rate_limit_threshold" {
  type        = number
  default     = 100
  description = "Rate limit threshold for WAF in requests per 5 minutes"
  nullable    = false
}


variable "active_target_group" {
  default     = "blue"
  type        = string
  description = "The active target group for blue/green deployments. Valid values are 'blue or 'green'."
  nullable    = false
}
locals {
  non_active_target_group         = var.active_target_group == "blue" ? aws_lb_target_group.green.arn : aws_lb_target_group.blue.arn
  db_access_sg_ids                = [module.web_service.security_group_id, module.sidekiq_service.security_group_id, module.ops_service.security_group_id]
  valkey_cache_availability_zones = var.valkey_failover_enabled ? [aws_subnet.private_subnet_a.availability_zone, aws_subnet.private_subnet_b.availability_zone] : [aws_subnet.private_subnet_a.availability_zone]
}
