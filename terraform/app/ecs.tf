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

  service_connect_defaults {
    namespace = aws_service_discovery_private_dns_namespace.internal.arn
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

data "aws_iam_role" "ecs_task_role" {
  name = "EcsTaskRole"
}

module "web_service" {
  source = "./modules/ecs_service"
  task_config = {
    environment          = local.web_envs
    secrets              = local.task_secrets["CORE"]
    cpu                  = 2048
    memory               = 4096
    execution_role_arn   = aws_iam_role.ecs_task_execution_role["CORE"].arn
    task_role_arn        = data.aws_iam_role.ecs_task_role.arn
    log_group_name       = aws_cloudwatch_log_group.ecs_log_group.name
    region               = var.region
    health_check_command = ["CMD-SHELL", "./bin/internal_healthcheck http://localhost:${local.container_ports.web}/health/database"]
  }
  export_prometheus_metrics = local.export_prometheus_metrics
  cloudwatch_agent_secrets = [
    {
      "name" : "PROMETHEUS_CONFIG_CONTENT",
      "valueFrom" : aws_ssm_parameter.prometheus_config.arn
    },
    {
      "name" : "CW_CONFIG_CONTENT",
      "valueFrom" : aws_ssm_parameter.cloudwatch_agent_config.arn
    }
  ]
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = aws_vpc.application_vpc.id
  }
  loadbalancer = {
    target_group_blue            = aws_lb_target_group.blue.arn
    target_group_green           = aws_lb_target_group.green.arn
    container_port               = local.container_ports.web
    production_listener_rule_arn = aws_lb_listener_rule.forward_to_app.arn
    test_listner_rule_arn        = aws_lb_listener_rule.forward_to_test.arn
    deploy_role_arn              = aws_iam_role.ecs_deploy.arn
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
  service_connect_config = {
    namespace = aws_service_discovery_private_dns_namespace.internal.arn
    services = [
      {
        port_name      = "web-port"
        discovery_name = "web"
        port           = local.container_ports.web
        dns_name       = "web"
      }
    ]
  }

  depends_on = [
    aws_iam_role.ecs_deploy,
    aws_rds_cluster_instance.core,
    aws_elasticache_replication_group.valkey
  ]
}

module "sidekiq_service" {
  source = "./modules/ecs_service"
  task_config = {
    environment          = local.sidekiq_envs
    secrets              = local.task_secrets["CORE"]
    cpu                  = 1024
    memory               = 6144
    execution_role_arn   = aws_iam_role.ecs_task_execution_role["CORE"].arn
    task_role_arn        = data.aws_iam_role.ecs_task_role.arn
    log_group_name       = aws_cloudwatch_log_group.ecs_log_group.name
    region               = var.region
    health_check_command = ["CMD-SHELL", "./bin/internal_healthcheck && grep -q '[s]idekiq' /proc/*/cmdline 2>/dev/null || exit 1"]
  }
  export_prometheus_metrics = local.export_prometheus_metrics
  cloudwatch_agent_secrets = [
    {
      "name" : "PROMETHEUS_CONFIG_CONTENT",
      "valueFrom" : aws_ssm_parameter.prometheus_config.arn
    },
    {
      "name" : "CW_CONFIG_CONTENT",
      "valueFrom" : aws_ssm_parameter.cloudwatch_agent_config.arn
    }
  ]
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
    aws_rds_cluster_instance.core,
    aws_elasticache_replication_group.valkey
  ]
}

module "reporting_service" {
  source = "./modules/ecs_service"
  task_config = {
    environment          = local.task_envs["REPORTING"]
    secrets              = local.task_secrets["REPORTING"]
    cpu                  = 1024
    memory               = 2048
    execution_role_arn   = aws_iam_role.ecs_task_execution_role["REPORTING"].arn
    task_role_arn        = data.aws_iam_role.ecs_task_role.arn
    log_group_name       = aws_cloudwatch_log_group.ecs_log_group.name
    region               = var.region
    health_check_command = ["CMD-SHELL", "wget --no-cache --spider -S http://localhost:${local.container_ports.reporting}/reports/healthcheck || exit 1"]
  }
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = aws_vpc.application_vpc.id
  }
  loadbalancer = {
    target_group_blue            = aws_lb_target_group.reporting_blue.arn
    target_group_green           = aws_lb_target_group.reporting_green.arn
    container_port               = local.container_ports.reporting
    production_listener_rule_arn = aws_lb_listener_rule.forward_to_reporting.arn
    test_listner_rule_arn        = aws_lb_listener_rule.forward_to_reporting_test.arn
    deploy_role_arn              = aws_iam_role.ecs_deploy.arn
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
  service_connect_config = {
    namespace = aws_service_discovery_private_dns_namespace.internal.arn
    services  = []
  }

  depends_on = [
    aws_iam_role.ecs_deploy
  ]
}

module "ops_service" {
  source       = "./modules/ecs_service"
  cluster_id   = aws_ecs_cluster.cluster.id
  cluster_name = aws_ecs_cluster.cluster.name
  environment  = var.environment
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = aws_vpc.application_vpc.id
  }
  task_config = {
    environment          = local.task_envs["CORE"]
    secrets              = local.task_secrets["CORE"]
    cpu                  = 1024
    memory               = 2048
    execution_role_arn   = aws_iam_role.ecs_task_execution_role["CORE"].arn
    task_role_arn        = data.aws_iam_role.ecs_task_role.arn
    log_group_name       = aws_cloudwatch_log_group.ecs_log_group.name
    region               = var.region
    health_check_command = ["CMD-SHELL", "echo 'alive' || exit 1"]

  }
  maximum_replica_count = var.enable_ops_service ? 1 : 0
  minimum_replica_count = var.enable_ops_service ? 1 : 0
  server_type           = "none"
  server_type_name      = "ops"
  readonly_file_system  = false
}
