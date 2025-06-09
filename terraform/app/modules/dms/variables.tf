variable "environment" {
  type        = string
  description = "String literal for the environment"
  nullable    = false
}

variable "source_endpoint" {
  type        = string
  description = "Source database endpoint"
  nullable    = false
}

variable "source_port" {
  type        = number
  description = "Source database port"
  nullable    = false
}

variable "source_database_name" {
  type        = string
  description = "Source database name"
  nullable    = false
}

variable "source_db_secret_arn" {
  type        = string
  description = "The secret arn for the source database"
  nullable    = false
}

variable "ecs_sg_ids" {
  type        = list(string)
  description = "List of ECS security group IDs"
  default     = []
  nullable    = false
}

variable "target_endpoint" {
  type        = string
  description = "Target database endpoint"
  nullable    = false
}

variable "target_port" {
  type        = number
  description = "Target database port"
  nullable    = false
}

variable "target_database_name" {
  type        = string
  description = "Target database name"
  nullable    = false
}

variable "target_db_secret_arn" {
  type        = string
  description = "The secret arn for the target database"
  nullable    = false
}

variable "target_db_rotation_arn" {
  type        = string
  description = "The secret rotation arn for the target database"
  nullable    = true
}

variable "engine_name" {
  description = "Database engine name (aurora or aurora-postgresql)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DMS"
  type        = list(string)
}

variable "rds_cluster_security_group_id" {
  description = "Security group ID of the RDS cluster"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  nullable    = false
}

locals {
  assume_role_policy_template = "${path.module}/../../templates/iam_assume_role.json.tpl"
}
