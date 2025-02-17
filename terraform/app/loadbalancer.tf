resource "aws_security_group" "lb_service_sg" {
  name        = var.resource_name.lb_security_group
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.application_vpc.id
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "lb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lb_egress_a" {
  type              = "egress"
  description       = "Allow egress to private subnet a for health checks"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.0.2.0/24"]
  security_group_id = aws_security_group.lb_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lb_egress_b" {
  type              = "egress"
  description       = "Allow egress to private subnet b for health checks"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.0.3.0/24"]
  security_group_id = aws_security_group.lb_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "app_lb" {
  name               = var.resource_name.loadbalancer
  internal           = false
  load_balancer_type = "application"
  access_logs {
    bucket = "nhse-mavis-logs-${var.environment}"
    prefix = "lb-access-logs"
    enabled = true
  }
  security_groups    = [aws_security_group.lb_service_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

resource "aws_lb_target_group" "blue" {
  name        = "mavis-blue-${var.environment}"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.application_vpc.id
  target_type = "ip"
  health_check {
    path                = "/up"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "green" {
  name        = "mavis-green-${var.environment}"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.application_vpc.id
  target_type = "ip"
  health_check {
    path                = "/up"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "app_listener_http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "app_listener_https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.dns_certificate_arn == null ? module.dns_route53[0].certificate_arn : var.dns_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

module "dns_route53" {
  count              = var.dns_certificate_arn == null ? 1 : 0
  source             = "./modules/dns"
  dns_name           = aws_lb.app_lb.dns_name
  zone_id            = aws_lb.app_lb.zone_id
  domain_name        = var.domain_name
  domain_name_prefix = var.environment
}
