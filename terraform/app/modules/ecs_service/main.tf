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
  name                              = "mavis-${var.environment}-${local.server_type_name}"
  cluster                           = var.cluster_id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.minimum_replica_count
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets         = var.network_params.subnets
    security_groups = [aws_security_group.this.id]
  }
  deployment_controller {
    type = var.deployment_controller
  }
  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_controller == "ECS" ? [1] : []
    content {
      enable   = true
      rollback = true
    }
  }
  dynamic "load_balancer" {
    for_each = var.loadbalancer != null ? [1] : []
    content {
      target_group_arn = var.loadbalancer.target_group_arn
      container_name   = var.container_name
      container_port   = var.loadbalancer.container_port
    }
  }
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer,
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
  container_definitions = jsonencode([
    {
      name                   = var.container_name
      image                  = "CHANGE_ME"
      essential              = true
      readonlyRootFileSystem = true
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
        }
      ]
      environment = concat(var.task_config.environment, [{ name = "SERVER_TYPE", value = var.server_type }])
      secrets     = var.task_config.secrets
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
  ])
}
