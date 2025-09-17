resource "aws_security_group_rule" "web_service_alb_ingress" {
  type                     = "ingress"
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  security_group_id        = module.web_service.security_group_id
  source_security_group_id = aws_security_group.lb_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "mavis-${var.environment}"

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }
}

module "web_service" {
  source = "./modules/ecs_service"
  task_config = {
    environment          = local.task_envs
    secrets              = local.task_secrets
    cpu                  = 1024
    memory               = 3072
    docker_image         = "${var.account_id}.dkr.ecr.eu-west-2.amazonaws.com/${var.docker_image}@${var.image_digest}"
    execution_role_arn   = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn        = aws_iam_role.ecs_task_role.arn
    log_group_name       = aws_cloudwatch_log_group.ecs_log_group.name
    region               = var.region
    health_check_command = ["CMD-SHELL", "./bin/internal_healthcheck http://localhost:4000/health/database"]
  }
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = aws_vpc.application_vpc.id
  }
  loadbalancer = {
    target_group_arn = local.ecs_initial_lb_target_group
    container_port   = 4000
  }
  autoscaling_policies = tomap({
    cpu = {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 60
      scale_in_cooldown      = 600
      scale_out_cooldown     = 300
    }
  })
  cluster_id            = aws_ecs_cluster.cluster.id
  cluster_name          = aws_ecs_cluster.cluster.name
  minimum_replica_count = var.minimum_web_replicas
  maximum_replica_count = var.maximum_web_replicas
  environment           = var.environment
  server_type           = "web"
  deployment_controller = "CODE_DEPLOY"
}

module "sidekiq_service" {
  source = "./modules/ecs_service"
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
    health_check_command = ["CMD-SHELL", "./bin/internal_healthcheck && grep -q '[s]idekiq' /proc/*/cmdline 2>/dev/null || exit 1"]
  }
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = aws_vpc.application_vpc.id
  }
  minimum_replica_count = var.minimum_sidekiq_replicas
  maximum_replica_count = var.maximum_sidekiq_replicas
  autoscaling_policies = tomap({
    cpu = {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 60
      scale_in_cooldown      = 600
      scale_out_cooldown     = 300
    }
  })
  cluster_id   = aws_ecs_cluster.cluster.id
  cluster_name = aws_ecs_cluster.cluster.name
  environment  = var.environment
  server_type  = "sidekiq"

  depends_on = [
    aws_elasticache_replication_group.valkey
  ]
}
