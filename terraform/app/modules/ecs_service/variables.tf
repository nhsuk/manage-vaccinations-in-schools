variable "environment" {
  type        = string
  description = "String literal for the environment"
}

variable "server_type" {
  type        = string
  description = "Type of server to be deployed"
  nullable    = false
}

variable "desired_count" {
  type = number
  description = "The initial amount of instances when creating the service"
  nullable = false
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
    cpu                 = number
    memory              = number
    docker_image        = string
    execution_role_arn  = string
    task_role_arn       = string
    log_group_name      = string
    region              = string
    health_check_command = list(string)
  })
  description = "Task configuration variables for the ECS background service"
  nullable    = false
}

variable "cluster_id" {
  type        = string
  description = "The ID of the ECS cluster."
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

variable "loadbalancer" {
  type = object({
    target_group_arn = string
    container_port   = number
  })
  description = "Load balancer configuration for the ECS service if the service should be user-facing"
  default     =  null
  nullable    = true
}

variable "deployment_controller" {
  type        = string
  description = "Deployment controller type for the ECS service"
  default     = "ECS"
  nullable    = false
}
