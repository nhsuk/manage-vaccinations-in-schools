resource "aws_iam_role" "grafana" {
  name = "grafana-role"
  assume_role_policy = templatefile(
    "../app/templates/iam_assume_role.json.tpl",
    { service_name = "grafana.amazonaws.com" }
  )
}

data "aws_iam_policy_document" "grafana" {
  statement {
    actions = [
      "cloudwatch:ListMetrics",
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "grafana" {
  name   = "grafana-policy"
  policy = data.aws_iam_policy_document.grafana.json
}

resource "aws_iam_role_policy_attachment" "grafana" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana.arn
}
