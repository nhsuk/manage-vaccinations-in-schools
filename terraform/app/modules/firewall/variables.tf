variable "vpc_id" {
  type        = string
  description = "The VPC ID"
  nullable    = false
}

variable "firewall_subnet_cidr" {
  type        = string
  description = "CIDR block for the firewall subnet"
  nullable    = false
}

variable "retain_logs" {
  type        = bool
  default     = false
  description = "Whether to retain logs for the VPC endpoint"
}

variable "environment" {
  type        = string
  description = "String literal for the environment"
  nullable    = false
}

variable "private_route_table_id" {
  type        = string
  description = "ID of the private route table"
  nullable    = false
}

variable "nat_gateway_id" {
  type        = string
  description = "ID of the NAT gateway"
  nullable    = false
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain logs for the VPC endpoint"
  nullable    = false
}

variable "ecs_security_group_id" {
  type        = string
  description = "ID of the ECS security group"
  nullable    = false
}
