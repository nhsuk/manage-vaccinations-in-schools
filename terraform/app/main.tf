terraform {
  required_version = "~> 1.10.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.4"
    }
  }

  backend "s3" {
    encrypt = true
  }
}

provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}
