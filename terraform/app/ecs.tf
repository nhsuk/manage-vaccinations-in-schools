resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg"
  description = "Security Group for communication with ECS"
  vpc_id      = aws_vpc.application_vpc.id
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "ecs_ingress_http" {
  type                     = "ingress"
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service_sg.id
  source_security_group_id = aws_security_group.lb_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ecs_talk_to_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service_sg.id
}

resource "aws_security_group_rule" "ecs_nat_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [aws_subnet.nat_subnet_a.cidr_block]
  security_group_id = aws_security_group.ecs_service_sg.id
}

resource "aws_ecs_cluster" "cluster" {
  name = "mavis-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "service" {
  name                              = "mavis-${var.environment}"
  cluster                           = aws_ecs_cluster.cluster.id
  task_definition                   = aws_ecs_task_definition.task_definition.arn
  desired_count                     = var.minimum_replicas
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    security_groups = [aws_security_group.ecs_service_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = local.container_name
    container_port   = 4000
  }
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [
      load_balancer,
      task_definition,
      # desired_count TODO: uncomment this when we proceed with enabling autoscaler
    ]
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "task-definition-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name = local.container_name
      image     = "${var.account_id}.dkr.ecr.eu-west-2.amazonaws.com/${var.docker_image}@${var.image_digest}"
      essential = true
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
        }
      ]
      environment = local.task_envs
      secrets     = local.task_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "${var.environment}-logs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:4000/up || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
  depends_on = [aws_cloudwatch_log_group.ecs_log_group]
}
