
resource "aws_ecs_cluster" "cluster" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "${local.name_prefix}-ecs"
  retention_in_days = 14
  skip_destroy      = false
}

data "aws_iam_role" "ecs_task_role" {
  name = "EcsTaskRole"
}

module "db_access_service" {
  source                = "../app/modules/ecs_service"
  cluster_id            = aws_ecs_cluster.cluster.id
  cluster_name          = aws_ecs_cluster.cluster.name
  environment           = var.environment
  maximum_replica_count = 1
  minimum_replica_count = 1
  network_params = {
    subnets = local.subnet_list
    vpc_id  = aws_vpc.vpc.id
  }
  server_type      = "none"
  server_type_name = "data-replication"
  task_config = {
    environment          = local.task_envs
    secrets              = local.task_secrets
    cpu                  = 1024
    memory               = 2048
    execution_role_arn   = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn        = data.aws_iam_role.ecs_task_role.arn
    log_group_name       = aws_cloudwatch_log_group.ecs_log_group.name
    region               = var.region
    health_check_command = ["CMD-SHELL", "echo 'alive' || exit 1"]
  }
  depends_on = [aws_rds_cluster_instance.instance]
}
