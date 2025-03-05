variable "dns_name" {
  type        = string
  nullable    = false
  description = "The DNS name to associate with the domain"
}

variable "zone_id" {
  type        = string
  nullable    = false
  description = "The zone ID to associate with the domain"
}

variable "domain_name" {
  type        = string
  nullable    = false
  description = "The domain name to associate with the domain"
}

variable "domain_name_prefix" {
  type        = string
  default     = ""
  description = "The domain name prefix to associate with the domain"
}
