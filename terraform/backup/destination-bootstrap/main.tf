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

module "terraform_state_bucket" {
  source      = "../../modules/s3"
  bucket_name = "mavisbackup-terraform-state"
}

resource "aws_s3_bucket_policy" "backend_bucket_block_http" {
  bucket = module.terraform_state_bucket.bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "block-backend-bucket-http-access"
    Statement = [
      {
        Sid    = "HTTPSOnly"
        Effect = "Deny"
        Principal = {
          "AWS" : "*"
        }
        Action = "s3:*"
        Resource = [
          module.terraform_state_bucket.arn,
          "${module.terraform_state_bucket.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
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
