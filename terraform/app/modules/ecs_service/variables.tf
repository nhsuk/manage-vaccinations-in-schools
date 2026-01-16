variable "environment" {
  type        = string
  description = "Application environment (for example production or staging)"
  nullable    = false
}

variable "server_type" {
  type        = string
  description = "Type of server to be deployed. This is set as an environment variable in the main container, and is used to determine how the application is launched."
  nullable    = false
}

variable "server_type_name" {
  type        = string
  description = "Name of the server type to be deployed."
  default     = null
  nullable    = true
}

variable "minimum_replica_count" {
  type        = number
  description = "Minimum amount of allowed replicas for the service. Also the replica count when creating th service."
  nullable    = false
}

variable "maximum_replica_count" {
  type        = number
  description = "The maximum amount of instances by which the service can scale. If equal to the minimum_replica_count, autoscaling will be disabled."
  nullable    = false
  validation {
    condition     = var.maximum_replica_count >= var.minimum_replica_count
    error_message = "Maximum replica count must be greater than initial replica count when autoscaling policies are defined and null otherwise"
  }
}

variable "autoscaling_policies" {
  type = map(object({
    predefined_metric_type = string
    target_value           = number
    scale_in_cooldown      = number
    scale_out_cooldown     = number
  }))
  description = "List of autoscaling policy configuration parameters for the ECS service"
  default     = {}
  nullable    = false
}


variable "task_config" {
  type = object({
    environment = list(object({
      name  = string
      value = string
    }))
    secrets = list(object({
      name      = string
      valueFrom = string
    }))
    cpu                  = number
    memory               = number
    execution_role_arn   = string
    task_role_arn        = string
    log_group_name       = string
    region               = string
    health_check_command = list(string)
  })
  description = "Task configuration variables for the task definition ECS service"
  nullable    = false
}

variable "cloudwatch_agent_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default     = null
  description = "List of secrets for CloudWatch Agent container"
  nullable    = true
}

variable "cluster_id" {
  type        = string
  description = "The ID of the ECS cluster."
  nullable    = false
}

variable "cluster_name" {
  type        = string
  description = "The name of the ECS cluster."
  nullable    = false
}

variable "network_params" {
  type = object({
    subnets = list(string)
    vpc_id  = string
  })
  description = "Network configuration for the ECS service"
  nullable    = false
}

variable "service_connect_config" {
  type = object({
    namespace = string
    services = list(object({
      port_name      = string
      discovery_name = string
      port           = number
      dns_name       = string
    }))
  })
  description = "Service Connect configuration for the ECS service. If this is not set, the service will not use Service Connect."
  default     = null
  nullable    = true
}

variable "loadbalancer" {
  type = object({
    target_group_blue            = string
    target_group_green           = string
    container_port               = number
    production_listener_rule_arn = string
    test_listner_rule_arn        = string
    deploy_role_arn              = string
  })
  description = "Load balancer configuration for the ECS service if the service should be user-facing"
  default     = null
  nullable    = true
}

variable "container_name" {
  type        = string
  description = "Name of the essential container in the task. Also the container which is serviced by the load balancer if applicable."
  default     = "application"
  nullable    = false
}

variable "container_port" {
  type        = number
  description = "The port on the container that the service will bind to. If not specified, it defaults to 4000."
  default     = 4000
  nullable    = false
}

variable "host_port" {
  type        = number
  description = "The port on the host that the container will bind to. If not specified, it defaults to the same value as container_port."
  default     = null
  nullable    = true
}

variable "readonly_file_system" {
  type        = bool
  description = "Whether the container's root filesystem should be mounted as read-only."
  default     = true
  nullable    = false
}

variable "export_prometheus_metrics" {
  type        = bool
  description = "Whether to export Prometheus metrics from the ECS service."
  default     = false
  nullable    = false
}

locals {
  autoscaling_enabled = var.maximum_replica_count > var.minimum_replica_count
  server_type_name    = var.server_type_name != null ? var.server_type_name : var.server_type

  prometheus_metric_export_containers = var.export_prometheus_metrics ? [
    {
      name      = "cloudwatch-agent",
      image     = "public.ecr.aws/cloudwatch-agent/cloudwatch-agent:1.300062.0b1304",
      secrets   = var.cloudwatch_agent_secrets == null ? [] : var.cloudwatch_agent_secrets
      essential = false
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = var.task_config.log_group_name
          awslogs-region        = var.task_config.region
          awslogs-stream-prefix = "${var.environment}-${local.server_type_name}-cwagent-logs"
        }
      }
    }
  ] : []
}
