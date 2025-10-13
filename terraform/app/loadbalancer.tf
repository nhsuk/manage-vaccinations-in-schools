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
    bucket  = var.access_logs_bucket
    prefix  = "lb-access-logs-${var.environment}"
    enabled = true
  }
  security_groups            = [aws_security_group.lb_service_sg.id]
  subnets                    = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "blue" {
  name        = "mavis-blue-${var.environment}"
  port        = local.container_ports.web
  protocol    = "HTTP"
  vpc_id      = aws_vpc.application_vpc.id
  target_type = "ip"
  health_check {
    path                = "/up"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 5
    timeout             = 4
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "green" {
  name        = "mavis-green-${var.environment}"
  port        = local.container_ports.web
  protocol    = "HTTP"
  vpc_id      = aws_vpc.application_vpc.id
  target_type = "ip"
  health_check {
    path                = "/up"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 5
    timeout             = 4
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "reporting_blue" {
  name        = "mavis-rep-blue-${var.environment}"
  port        = local.container_ports.reporting
  protocol    = "HTTP"
  vpc_id      = aws_vpc.application_vpc.id
  target_type = "ip"
  health_check {
    path                = "/reports/healthcheck"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "reporting_green" {
  name        = "mavis-rep-green-${var.environment}"
  port        = local.container_ports.reporting
  protocol    = "HTTP"
  vpc_id      = aws_vpc.application_vpc.id
  target_type = "ip"
  health_check {
    path                = "/reports/healthcheck"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "dump" {
  name        = "dump-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.application_vpc.id
}

resource "aws_lb_listener" "app_listener_http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dump.arn
  }
}

resource "aws_lb_listener" "app_listener_https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = local.default_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dump.arn
  }
}

resource "aws_lb_listener_certificate" "https_sni_certificates" {
  count           = length(local.additional_sni_certificates)
  listener_arn    = aws_lb_listener.app_listener_https.arn
  certificate_arn = local.additional_sni_certificates[count.index]
}

resource "aws_lb_listener_rule" "forward_to_app" {
  listener_arn = aws_lb_listener.app_listener_https.arn
  priority     = 50000
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
  condition {
    host_header {
      values = local.host_headers
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_listener_rule" "forward_to_test" {
  listener_arn = aws_lb_listener.app_listener_https.arn
  priority     = 20

  # Action to forward traffic to the target group
  action {
    type             = "forward"
    target_group_arn = local.non_active_target_group
  }

  # Condition based on HTTP header
  condition {
    http_header {
      http_header_name = "X-Environment"
      values           = ["test"]
    }
  }
  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_listener_rule" "forward_to_reporting" {
  listener_arn = aws_lb_listener.app_listener_https.arn
  priority     = 49000
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.reporting_blue.arn
  }
  condition {
    path_pattern {
      values = var.reporting_endpoints
    }
  }
  condition {
    host_header {
      values = local.host_headers
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_listener_rule" "forward_to_reporting_test" {
  listener_arn = aws_lb_listener.app_listener_https.arn
  priority     = 15
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.reporting_green.arn
  }
  condition {
    path_pattern {
      values = var.reporting_endpoints
    }
  }
  condition {
    host_header {
      values = local.host_headers
    }
  }

  condition {
    http_header {
      http_header_name = "X-Environment"
      values           = ["test"]
    }
  }
  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_listener_rule" "redirect_to_https" {
  listener_arn = aws_lb_listener.app_listener_http.arn
  priority     = 50000
  action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
  condition {
    host_header {
      values = local.host_headers
    }
  }
}

module "dns_route53" {
  count        = var.dns_certificate_arn == null ? 1 : 0
  source       = "./modules/dns"
  dns_name     = aws_lb.app_lb.dns_name
  zone_id      = aws_lb.app_lb.zone_id
  zone_name    = var.zone_name
  domain_names = tolist(toset(values(var.http_hosts)))
}
