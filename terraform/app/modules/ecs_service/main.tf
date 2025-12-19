terraform {
  required_version = "~> 1.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }
  }
}

resource "aws_security_group" "this" {
  name        = "${local.server_type_name}-service-${var.environment}"
  description = "Security Group for communication with ECS Service"
  vpc_id      = var.network_params.vpc_id
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}

resource "aws_ecs_service" "this" {
  name                               = "mavis-${var.environment}-${local.server_type_name}"
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.minimum_replica_count
  launch_type                        = "FARGATE"
  enable_execute_command             = true
  health_check_grace_period_seconds  = 60
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  wait_for_steady_state              = true
  sigint_rollback                    = true


  network_configuration {
    subnets         = var.network_params.subnets
    security_groups = [aws_security_group.this.id]
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  dynamic "deployment_configuration" {
    for_each = var.loadbalancer != null ? [1] : []
    content {
      strategy             = "BLUE_GREEN"
      bake_time_in_minutes = 1
    }
  }
  dynamic "load_balancer" {
    for_each = var.loadbalancer != null ? [1] : []
    content {
      target_group_arn = var.loadbalancer.target_group_blue
      container_name   = var.container_name
      container_port   = var.loadbalancer.container_port
      advanced_configuration {
        alternate_target_group_arn = var.loadbalancer.target_group_green
        production_listener_rule   = var.loadbalancer.production_listener_rule_arn
        role_arn                   = var.loadbalancer.deploy_role_arn
        test_listener_rule         = var.loadbalancer.test_listner_rule_arn
      }
    }
  }
  dynamic "service_connect_configuration" {
    for_each = var.service_connect_config != null ? [1] : []
    content {
      enabled   = true
      namespace = var.service_connect_config.namespace
      dynamic "service" {
        for_each = var.service_connect_config.services
        content {
          port_name      = service.value.port_name
          discovery_name = service.value.discovery_name
          client_alias {
            port     = service.value.port
            dns_name = service.value.dns_name
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "mavis-${local.server_type_name}-task-definition-${var.environment}-template"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_config.cpu
  memory                   = var.task_config.memory
  execution_role_arn       = var.task_config.execution_role_arn
  task_role_arn            = var.task_config.task_role_arn
  container_definitions = jsonencode(concat([
    {
      name                   = var.container_name
      image                  = "CHANGE_ME"
      essential              = true
      readonlyRootFileSystem = var.readonly_file_system
      portMappings = [
        {
          name          = var.service_connect_config != null && length(var.service_connect_config.services) > 0 ? var.service_connect_config.services[0].port_name : null
          containerPort = var.container_port
          hostPort      = var.host_port == null ? var.container_port : var.host_port
          protocol      = "tcp"
        }
      ]
      environment = concat(
        var.task_config.environment, [
          {
            name  = "SERVER_TYPE",
            value = var.server_type
          },
          {
            name  = "SERVICE_NAME"
            value = "mavis-${var.environment}-${local.server_type_name}"
          }
      ])
      secrets = var.task_config.secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.task_config.log_group_name
          awslogs-region        = var.task_config.region
          awslogs-stream-prefix = "${var.environment}-${local.server_type_name}-logs"
        }
      }
      healthCheck = {
        command     = var.task_config.health_check_command
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
    ],
    local.prometheus_metric_export_containers
  ))
}
