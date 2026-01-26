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

module "s3_endtoend_reports" {
  source                   = "../modules/s3"
  bucket_name              = "endtoendtest-reports"
  logging_target_bucket_id = data.aws_s3_bucket.access_logs.id
  logging_target_prefix    = "endtoendtest-reports/"

  additional_policy_statements = [
    {
      sid    = "AllowCloudFrontRead"
      effect = "Allow"
      actions = [
        "s3:GetObject",
      ]
      resources = [
        "arn:aws:s3:::endtoendtest-reports/*",
      ]
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudfront.amazonaws.com"]
        }
      ]
      condition = {
        test     = "StringEquals"
        variable = "AWS:SourceArn"
        values   = [aws_cloudfront_distribution.endtoend_reports.arn]
      }
    }
  ]
}

resource "aws_cloudfront_origin_access_control" "endtoend_reports" {
  name                              = "endtoend-reports-oac"
  description                       = "OAC for end-to-end test reports bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "endtoend_reports" {
  enabled             = true
  comment             = "End-to-end test reports"
  default_root_object = "index.html"

  origin {
    domain_name              = module.s3_endtoend_reports.bucket_regional_domain_name
    origin_id                = "s3-endtoend-reports"
    origin_access_control_id = aws_cloudfront_origin_access_control.endtoend_reports.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-endtoend-reports"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
