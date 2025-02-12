terraform {
  backend "local" {}
}
provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = var.environment_string
    }
  }
}

# S3 bucket to store the terraform state
resource "aws_s3_bucket" "s3_bucket_backend" {
  bucket = "nhse-mavis-terraform-state-${var.environment_string}"
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.s3_bucket_backend.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "s3_bucket_backend_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
  bucket     = aws_s3_bucket.s3_bucket_backend.id
  acl        = "private"
}

resource "aws_s3_bucket_versioning" "s3_bucket_version" {
  bucket = aws_s3_bucket.s3_bucket_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "terraform_folder" {
  bucket = aws_s3_bucket.s3_bucket_backend.id
  key    = "terraform.tfstate"
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_access" {
  bucket                  = aws_s3_bucket.s3_bucket_backend.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "dynamodb_lock_table" {
  name         = "mavis-state-lock-${var.environment_string}"
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

resource "aws_ecr_repository" "ecr_repository" {
  name = "mavis-${var.environment_string}"
}


variable "environment_string" {
  type        = string
  description = "String literal for the environment"
}
