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

resource "aws_ecs_task_definition" "regression" {
  family                   = "${var.identifier}-regression-task-definition-template"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "mavis-regression-db"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-2.amazonaws.com/mavis/dev/postgres_db:latest"
      essential = true
      environment = [
        { name = "POSTGRES_DB",              value = "manage_vaccinations_development" },
        { name = "POSTGRES_PASSWORD",        value = "postgres" },
        { name = "POSTGRES_HOST_AUTH_METHOD", value = "trust" }
      ]
      healthCheck = {
        command     = [
          "CMD-SHELL",
          "pg_isready -U postgres -d manage_vaccinations_development && psql -U postgres -d manage_vaccinations_development -tAc 'SELECT 1 FROM locations LIMIT 1' | grep -q 1 || exit 1"
        ]
        interval    = 10
        timeout     = 5
        retries     = 6
        startPeriod = 120
      }
      # (Optional) Add log configuration if needed
    },
    {
      name      = "mavis-regression"
      image     = "CHANGE_ME"
      essential = true
      environment = [
        { name = "DATABASE_HOST",     value = "localhost" },
        { name = "DATABASE_USER",     value = "postgres" },
        { name = "DATABASE_PASSWORD", value = "postgres" },
        { name = "POSTGRES_DB",       value = "manage_vaccinations_development" },
        { name = "RAILS_MASTER_KEY",  value = "intentionally-insecure-dev-key00" },
        { name = "SKIP_TEST_DATABASE", value = "true" }
      ]
      portMappings = [
        { containerPort = 4000, hostPort = 4000, protocol = "tcp" }
      ]
      # Use wait-for-db.sh as entrypoint/command
      command = ["./wait-for-db.sh", "bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:4000/health/database || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 150
      }
      dependsOn = [
        {
          containerName = "mavis-regression-db"
          condition     = "HEALTHY"
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
    }
  ])

  tags = {
    Name = "${var.identifier}-regression"
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

resource "aws_security_group" "regression" {
  name        = "${var.identifier}-regression-sg"
  description = "Security group for ${var.identifier} ecs task"
  vpc_id      = aws_vpc.vpc.id
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "regression_ingress" {
  type              = "ingress"
  description       = "Allow all ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.regression.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "regression_egress" {
  type              = "egress"
  description       = "Allow all ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.regression.id
  lifecycle {
    create_before_destroy = true
  }
}
