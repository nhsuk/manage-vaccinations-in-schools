terraform {
  required_version = "~> 1.10.5"
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87"
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

#### Dynamo DB table for terraform state locking
resource "aws_dynamodb_table" "dynamodb_lock_table" {
  name         = "mavisbackup-terraform-state-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}
