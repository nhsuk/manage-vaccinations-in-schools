variable "vpc_id" {
  type        = string
  description = "The VPC ID"
  nullable    = false
}

variable "service_name" {
  type        = string
  description = "Service name of the VPC endpoint"
  nullable    = false
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs in which to create a network interface for this endpoint"
  nullable    = false
}

variable "ingress_ports" {
  type        = list(number)
  description = "Ports for which ingress is allowed"
  nullable    = false
}

variable "source_security_group" {
  type        = string
  description = "Security group that is allowed for ingress"
  nullable    = false
}

variable "tags" {
  description = "Tags to set on the VPC endpoint"
  type        = map(string)
  default     = {}
}
