resource "aws_iam_role" "grafana" {
  name = "mavis-grafana-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "393416225559"
          }
          StringLike = {
            "aws:SourceArn" = "arn:aws:grafana:eu-west-2:393416225559:/workspaces/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonGrafanaCloudWatchAccess"
}
