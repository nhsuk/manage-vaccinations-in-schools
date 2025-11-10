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

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.identifier}-task-definition-template"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name                   = "${var.identifier}-container"
      image                  = "CHANGE_ME"
      essential              = true
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
    Name = var.identifier
  }
}

resource "aws_security_group" "ecs_task_sg" {
  name        = "${var.identifier}-sg"
  description = "Security group for ${var.identifier} ecs task"
  vpc_id      = aws_vpc.vpc.id
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "ecs_task_egress" {
  type              = "egress"
  description       = "Allow all egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_task_sg.id
  lifecycle {
    create_before_destroy = true
  }
}