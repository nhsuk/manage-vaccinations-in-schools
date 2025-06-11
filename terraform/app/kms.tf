resource "aws_kms_key" "rds_cluster" {
  description = "Custom KMS key for new Aurora cluster"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccount"
        Effect = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::${var.account_id}:root"]
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}
