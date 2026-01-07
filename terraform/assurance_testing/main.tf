terraform {
  required_version = "~> 1.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }
  }

  backend "s3" {
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
    bucket       = "nhse-mavis-terraform-state"
    key          = "terraform-assurance-testing.tfstate"
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_ecr_repository" "performance" {
  name                 = "performancetest"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository" "mavis_development" {
  name                 = "mavis/development"
  image_tag_mutability = "IMMUTABLE"
}


resource "aws_ecr_lifecycle_policy" "performance" {
  repository = aws_ecr_repository.performance.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire images older than 1 month",
        selection = {
          tagStatus   = "any",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "mavis_development" {
  repository = aws_ecr_repository.mavis_development.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only 30 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

data "aws_s3_bucket" "access_logs" {
  bucket = "nhse-mavis-access-logs"
}

module "s3_performance_reports" {
  source                   = "../modules/s3"
  bucket_name              = "performancetest-reports"
  logging_target_bucket_id = data.aws_s3_bucket.access_logs.id
  logging_target_prefix    = "performancetest-reports/"
}
