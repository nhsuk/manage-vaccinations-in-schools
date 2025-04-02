variable "dns_name" {
  type        = string
  nullable    = false
  description = "DNS name to create DNS certificate for"
}

variable "zone_id" {
  type        = string
  nullable    = false
  description = "ID of existing DNS zone to create DNS certificate for"
}

variable "zone_name" {
  type        = string
  nullable    = false
  description = "Name of existing DNS zone name to create DNS certificate for"
}

variable "domain_names" {
  type        = list(string)
  nullable    = false
  description = "List of domain names to create DNS records for"
}
