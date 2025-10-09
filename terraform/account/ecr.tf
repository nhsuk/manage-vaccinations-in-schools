resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = "BASIC"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}

resource "aws_ecr_repository" "mavis" {
  name                 = "mavis/webapp"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "mavis" {
  repository = aws_ecr_repository.mavis.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire images older than 3 months",
        selection = {
          tagStatus   = "any",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 90,
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_repository" "mavis_reporting" {
  name                 = "mavis/reporting"
  image_tag_mutability = "MUTABLE"
}