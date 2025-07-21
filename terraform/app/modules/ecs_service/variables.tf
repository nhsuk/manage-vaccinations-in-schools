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
    docker_image         = string
    execution_role_arn   = string
    task_role_arn        = string
    log_group_name       = string
    region               = string
    health_check_command = list(string)
  })
  description = "Task configuration variables for the task definition ECS service"
  nullable    = false
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

variable "service_discovery_service_arn" {
  type        = string
  description = "Arn of the Service Discovery service for the ECS service. If this is not set, the service will not be discoverable via Cloud Map."
  default     = null
  nullable    = true
}

variable "loadbalancer" {
  type = object({
    target_group_arn = string
    container_port   = number
  })
  description = "Load balancer configuration for the ECS service if the service should be user-facing"
  default     = null
  nullable    = true
}

variable "deployment_controller" {
  type        = string
  description = "Deployment controller type for the ECS service"
  default     = "ECS"
  nullable    = false
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

locals {
  autoscaling_enabled = var.maximum_replica_count > var.minimum_replica_count
  server_type_name    = var.server_type_name != null ? var.server_type_name : var.server_type
}
