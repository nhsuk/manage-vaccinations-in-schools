variable "dns_name" {
  type     = string
  nullable = false
}

variable "zone_id" {
  type     = string
  nullable = false
}

variable "domain_name" {
  type     = string
  nullable = false
}

variable "domain_name_prefix" {
  type    = string
  default = ""
}
