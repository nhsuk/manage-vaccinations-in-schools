resource "aws_flow_log" "vpc_flowlogs" {
  iam_role_arn             = aws_iam_role.vpc_flowlogs.arn
  log_destination          = aws_cloudwatch_log_group.vpc_log_group.arn
  max_aggregation_interval = 60
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.application_vpc.id
  depends_on               = [time_sleep.wait_to_delete_flowlogs_group]
}

resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name              = var.resource_name.cloudwatch_vpc_log_group
  retention_in_days = var.vpc_log_retention_days
  skip_destroy      = local.is_production
}

resource "time_sleep" "wait_to_delete_flowlogs_group" {
  destroy_duration = "3m"
  depends_on       = [aws_cloudwatch_log_group.vpc_log_group]
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "mavis-${var.environment}-ecs"
  retention_in_days = var.ecs_log_retention_days
  skip_destroy      = local.is_production
}
