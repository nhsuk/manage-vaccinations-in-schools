resource "aws_security_group" "this" {
  name        = "ecs-background-service-${var.environment}"
  description = "Security Group for communication with Background ECS Service"
  vpc_id      = var.network_params.vpc_id
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "this" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}

resource "aws_ecs_service" "this" {
  name                              = "mavis-${var.environment}-background"
  cluster                           = var.cluster_id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets         = var.network_params.subnets
    security_groups = [aws_security_group.this.id]
  }
  deployment_controller {
    type = "ECS"
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "background-task-definition-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = var.task_config.execution_role_arn
  task_role_arn            = var.task_config.task_role_arn
  container_definitions = jsonencode([
    {
      name      = var.task_config.container_name
      image     = var.task_config.docker_image
      essential = true
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
        }
      ]
      environment = concat(var.task_config.environment, [{name  = "SERVER_TYPE", value = "background"}])
      secrets     = var.task_config.secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.task_config.log_group_name
          awslogs-region        = var.task_config.region
          awslogs-stream-prefix = var.task_config.log_stream_prefix
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:4000 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}
