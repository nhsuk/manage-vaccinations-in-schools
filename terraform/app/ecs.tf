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
    value = "enabled"
  }
}

module "web_service" {
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
    health_check_command = ["CMD-SHELL", "curl -f http://localhost:4000/up || exit 1"]
  }
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = aws_vpc.application_vpc.id
  }
  loadbalancer = {
    target_group_arn = local.ecs_initial_lb_target_group
    container_port   = 4000
  }
  cluster_id            = aws_ecs_cluster.cluster.id
  environment           = var.environment
  server_type           = "web"
  desired_count         = var.minimum_web_replicas
  deployment_controller = "CODE_DEPLOY"
}

module "good_job_service" {
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
    health_check_command = ["CMD-SHELL", "curl -f http://localhost:4000 || exit 1"]
  }
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = aws_vpc.application_vpc.id
  }
  cluster_id    = aws_ecs_cluster.cluster.id
  environment   = var.environment
  server_type   = "good-job"
  desired_count = var.minimum_good_job_replicas
}
