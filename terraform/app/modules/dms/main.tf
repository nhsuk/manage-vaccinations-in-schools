terraform {
  required_version = "~> 1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}
