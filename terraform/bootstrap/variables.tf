variable "environment" {
  type        = string
  description = "String literal for the environment"
}

locals {
  suffix = var.environment == "production" ? "-production" : ""
}
