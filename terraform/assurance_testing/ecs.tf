resource "aws_ecs_cluster" "this" {
  name = var.identifier
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.identifier}-ecs"
  retention_in_days = 7
  skip_destroy      = false
}

resource "aws_ecs_task_definition" "performance" {
  family                   = "${var.identifier}-performance-task-definition-template"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "performancetest-container"
      image     = "CHANGE_ME"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "${var.identifier}-logs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.identifier}-performance"
  }
}

resource "aws_ecs_task_definition" "containerized_development" {
  family                   = "${var.identifier}-mavis-development-task-definition-template"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "mavis-development-web"
      image     = "CHANGE_ME"
      essential = true
      environment = [
        {
          name  = "DATABASE_HOST"
          value = "localhost"
        },
        {
          name  = "DATABASE_USER"
          value = "postgres"
        },
        {
          name  = "DATABASE_PASSWORD"
          value = "postgres"
        },
        {
          name  = "RAILS_MASTER_KEY"
          value = "intentionally-insecure-dev-key00"
        },
        {
          name  = "SKIP_TEST_DATABASE"
          value = "true"
        },
        {
          name  = "SERVER_TYPE"
          value = "web"
        }
      ]
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "${var.identifier}-logs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:4000/health/database || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 90
      }
      dependsOn = [{
        containerName = "mavis-development-db"
        condition     = "HEALTHY"
      }]
    },
    {
      name      = "mavis-development-sidekiq"
      image     = "CHANGE_ME"
      essential = false
      environment = [
        {
          name  = "DATABASE_HOST"
          value = "localhost"
        },
        {
          name  = "DATABASE_USER"
          value = "postgres"
        },
        {
          name  = "DATABASE_PASSWORD"
          value = "postgres"
        },
        {
          name  = "RAILS_MASTER_KEY"
          value = "intentionally-insecure-dev-key00"
        },
        {
          name  = "SKIP_TEST_DATABASE"
          value = "true"
        },
        {
          name  = "SERVER_TYPE"
          value = "sidekiq"
        },
        {
          name  = "HTTP_PORT"
          value = "5000"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "${var.identifier}-development-logs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "grep -q '[s]idekiq' /proc/*/cmdline 2>/dev/null || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 90
      }
      dependsOn = [{
        containerName = "mavis-development-db"
        condition     = "HEALTHY"
      }]
    },
    {
      name      = "mavis-development-db"
      image     = "CHANGE_ME"
      essential = false
      environment = [
        {
          name  = "POSTGRES_HOST_AUTH_METHOD"
          value = "trust"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "pg_isready"]
        interval    = 10
        timeout     = 5
        retries     = 5
        startPeriod = 60
      }
    },
    {
      name      = "mavis-development-redis"
      image     = "redis:8.4.0-alpine"
      essential = false
    }
  ])
  tags = {
    Name = "${var.identifier}-mavis-development"
  }
}

resource "aws_security_group" "performance" {
  name        = "${var.identifier}-performance-sg"
  description = "Security group for ${var.identifier} ecs task"
  vpc_id      = aws_vpc.vpc.id
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "performance_egress" {
  type              = "egress"
  description       = "Allow all egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.performance.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "mavis_development" {
  name        = "${var.identifier}-mavis-development-sg"
  description = "Security group for ${var.identifier} ecs task"
  vpc_id      = aws_vpc.vpc.id
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "mavis_development_ingress" {
  type              = "ingress"
  description       = "Allow all ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mavis_development.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mavis_development_egress" {
  type              = "egress"
  description       = "Allow all ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mavis_development.id
  lifecycle {
    create_before_destroy = true
  }
}
