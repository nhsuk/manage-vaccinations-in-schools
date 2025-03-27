variable "environment" {
  type        = string
  description = "String literal for the environment"
}

variable "container_name" {
  type        = string
  description = "Name of essential container in the task definition"
  nullable    = false
}

variable "task_config" {
  type = object({
    environment = list(object({
      name  = string
      value = string
    }))
    secrets = list(object({
      name  = string
      value = string
    }))
    cpu                = number
    memory             = number
    docker_image       = string
    execution_role_arn = string
    task_role_arn      = string
    log_group_name      = string
    region             = string
    log_stream_prefix  = string
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
