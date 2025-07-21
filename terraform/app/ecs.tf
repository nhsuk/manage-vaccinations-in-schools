resource "aws_security_group_rule" "web_service_alb_ingress" {
  type                     = "ingress"
  from_port                = local.container_ports.web
  to_port                  = local.container_ports.web
  protocol                 = "tcp"
  security_group_id        = module.web_service.security_group_id
  source_security_group_id = aws_security_group.lb_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "reporting_service_alb_ingress" {
  type                     = "ingress"
  from_port                = local.container_ports.reporting
  to_port                  = local.container_ports.reporting
  protocol                 = "tcp"
  security_group_id        = module.reporting_service.security_group_id
  source_security_group_id = aws_security_group.lb_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "reporting_to_web_service" {
  type                     = "ingress"
  from_port                = local.container_ports.web
  to_port                  = local.container_ports.web
  protocol                 = "tcp"
  security_group_id        = module.web_service.security_group_id
  source_security_group_id = module.reporting_service.security_group_id
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

resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = "mavis.${var.environment}.aws-int"
  description = "Private namespace for ECS service discovery"
  vpc         = aws_vpc.application_vpc.id

  tags = {
    Name = "ecs-service-discovery-${var.environment}"
  }
}

resource "aws_service_discovery_service" "web" {
  name = "web"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10 # TODO: Decide on optimal caching time for DNS records
      type = "A"
    }
    routing_policy = "MULTIVALUE" # For multiple tasks; use "WEIGHTED" if custom weights needed
  }

  tags = {
    Name = "maivs-${var.environment}-web"
  }
}

module "web_service" {
  source = "./modules/ecs_service"
  task_config = {
    environment = concat(local.task_envs, [
      {
        name  = "MAVIS__REPORTING_API__CLIENT_APP__CLIENT_ID"
        value = aws_secretsmanager_secret.jwt_sign.name
      }
      ]
    )
    secrets = concat(
      local.task_secrets,
      [{
        name      = "MAVIS__REPORTING_API__CLIENT_APP__SECRET"
        valueFrom = aws_secretsmanager_secret.jwt_sign.arn
      }]
    )
    cpu                  = 1024
    memory               = 2048
    docker_image         = "${var.account_id}.dkr.ecr.eu-west-2.amazonaws.com/${var.docker_image}@${var.image_digest}"
    execution_role_arn   = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn        = aws_iam_role.ecs_task_role.arn
    log_group_name       = aws_cloudwatch_log_group.ecs_log_group.name
    region               = var.region
    health_check_command = ["CMD-SHELL", "./bin/internal_healthcheck http://localhost:${local.container_ports.web}/health/database"]
  }
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = aws_vpc.application_vpc.id
  }
  loadbalancer = {
    target_group_arn = local.ecs_initial_lb_target_group
    container_port   = local.container_ports.web
  }
  autoscaling_policies = tomap({
    cpu = {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 60
      scale_in_cooldown      = 600
      scale_out_cooldown     = 300
    }
  })
  cluster_id                    = aws_ecs_cluster.cluster.id
  cluster_name                  = aws_ecs_cluster.cluster.name
  minimum_replica_count         = var.minimum_web_replicas
  maximum_replica_count         = var.maximum_web_replicas
  environment                   = var.environment
  server_type                   = "web"
  deployment_controller         = "CODE_DEPLOY"
  service_discovery_service_arn = aws_service_discovery_service.web.arn
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
    health_check_command = ["CMD-SHELL", "./bin/internal_healthcheck http://localhost:${local.container_ports.good_job}/status/connected"]
  }
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = aws_vpc.application_vpc.id
  }
  minimum_replica_count = var.good_job_replicas
  maximum_replica_count = var.good_job_replicas
  cluster_id            = aws_ecs_cluster.cluster.id
  cluster_name          = aws_ecs_cluster.cluster.name
  environment           = var.environment
  server_type           = "good-job"
}

module "reporting_service" {
  source = "./modules/ecs_service"
  task_config = {
    environment = [
      {
        name  = "VALKEY_ADDRESS"
        value = aws_elasticache_serverless_cache.reporting_service.endpoint[0].address
      },
      {
        name  = "VALKEY_PORT"
        value = aws_elasticache_serverless_cache.reporting_service.endpoint[0].port
      },
      {
        name  = "CLIENT_ID"
        value = aws_secretsmanager_secret.jwt_sign.name
      }
    ]
    secrets = [{
      name      = "CLIENT_SECRET"
      valueFrom = aws_secretsmanager_secret.jwt_sign.arn
    }]
    cpu                  = 1024
    memory               = 2048
    docker_image         = local.reporting_image
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
  loadbalancer = {
    target_group_arn = local.reporting_initial_lb_target_group
    container_port   = local.container_ports.reporting
  }
  autoscaling_policies = tomap({
    cpu = {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 60
      scale_in_cooldown      = 600
      scale_out_cooldown     = 300
    }
  })
  container_port        = local.container_ports.reporting
  minimum_replica_count = var.minimum_reporting_replicas
  maximum_replica_count = var.maximum_reporting_replicas
  cluster_id            = aws_ecs_cluster.cluster.id
  cluster_name          = aws_ecs_cluster.cluster.name
  environment           = var.environment
  server_type           = "reporting"
  deployment_controller = "CODE_DEPLOY"
}

# Fetch the task definition for the reporting service if it exists, as it has a separate deployment process/pipeline
# TODO: Remove this workaround when extracting infrastructure from the monorepo is complete
data "aws_ecs_task_definition" "reporting" {
  count           = var.reporting_digest == null ? 1 : 0
  task_definition = "arn:aws:ecs:${var.region}:${var.account_id}:task-definition/mavis-reporting-task-definition-${var.environment}"
}

locals {
  reporting_image = (
    var.reporting_digest == null ?
    jsondecode(data.aws_ecs_task_definition.reporting[0].container_definitions)[0]["image"] :
    "${var.account_id}.dkr.ecr.eu-west-2.amazonaws.com/mavis/reporting@${var.reporting_digest}"
  )
}
