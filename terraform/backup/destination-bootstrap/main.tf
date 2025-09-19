terraform {
  required_version = "~> 1.13.3"
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }
  }
}
provider "aws" {
  region = "eu-west-2"
}

module "access_logs_bucket" {
  source      = "../../modules/s3"
  bucket_name = "nhse-mavis-destination-access-logs"
}

module "terraform_state_bucket" {
  source                   = "../../modules/s3"
  bucket_name              = "mavisbackup-terraform-state"
  logging_target_bucket_id = module.access_logs_bucket.bucket_id
  logging_target_prefix    = "terraform-state/"
}
