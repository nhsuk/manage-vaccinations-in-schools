resource "aws_flow_log" "vpc_flowlogs" {
  iam_role_arn    = aws_iam_role.vpc_flowlogs.arn
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.application_vpc.id
}

resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name              = var.resource_name.cloudwatch_vpc_log_group
  retention_in_days = var.vpc_log_retention_days
  skip_destroy      = local.is_production
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "mavis-${var.environment_string}-ecs"
  retention_in_days = var.ecs_log_retention_days
  skip_destroy      = local.is_production
}
