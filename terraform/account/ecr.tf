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
  policy     = file("resources/ecr_lifecycle_policy.json")
}

resource "aws_ecr_repository" "mavis_reporting" {
  name                 = "mavis/reporting"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "mavis_reporting" {
  repository = aws_ecr_repository.mavis_reporting.name
  policy     = file("resources/ecr_lifecycle_policy.json")
}

resource "aws_ecr_repository" "mavis_ops" {
  name                 = "mavis/ops"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "mavis_ops" {
  repository = aws_ecr_repository.mavis_ops.name
  policy     = file("resources/ecr_lifecycle_policy.json")
}

resource "aws_ecr_repository" "development_postgres_db" {
  name                 = "mavis/development/postgres_db"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "development_postgres_db" {
  repository = aws_ecr_repository.development_postgres_db.name
  policy     = file("resources/ecr_lifecycle_policy_keep_10.json")
}
