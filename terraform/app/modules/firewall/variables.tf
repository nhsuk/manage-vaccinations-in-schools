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

variable "nat_gateway_ids" {
  type        = map(string)
  description = "Map of availability zones to NAT Gateway IDs"
  nullable = false
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain logs for the VPC endpoint"
  nullable    = false
}

locals {
  azs            = keys(var.nat_gateway_ids)
  subnet_count   = length(local.azs)
  newbits        = ceil(log(local.subnet_count, 2))
  subnet_cidrs   = [for i in range(local.subnet_count) : cidrsubnet(var.firewall_subnet_cidr, local.newbits, i)]
}
