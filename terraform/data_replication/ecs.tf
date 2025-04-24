
resource "aws_ecs_cluster" "cluster" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "${local.name_prefix}-ecs"
  retention_in_days = 1
  skip_destroy      = false
}


module "db_access_service" {
  source                = "../app/modules/ecs_service"
  cluster_id            = aws_ecs_cluster.cluster.id
  cluster_name          = aws_ecs_cluster.cluster.name
  environment           = var.environment
  naming_prefix         = "mavis-data-replication-"
  maximum_replica_count = 1
  minimum_replica_count = 1
  network_params = {
    subnets = local.subnet_list
    vpc_id  = aws_vpc.vpc.id
  }
  server_type = "good-job"
  task_config = {
    environment          = local.task_envs
    secrets              = local.task_secrets
    cpu                  = 1024
    memory               = 2048
    docker_image         = "${var.account_id}.dkr.ecr.eu-west-2.amazonaws.com/${var.docker_image}@${var.image_digest}"
    execution_role_arn   = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn        = aws_iam_role.ecs_task_role.arn
    log_group_name       = aws_cloudwatch_log_group.ecs_log_group.name
    region               = var.region
    health_check_command = ["CMD-SHELL", "curl -f http://localhost:4000 || exit 1"]
  }
  depends_on = [aws_rds_cluster_instance.instance]
}
