resource "aws_vpc_endpoint" "this" {
  vpc_id              = var.vpc_id
  service_name        = var.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.this.id]
  private_dns_enabled = true

  tags = var.tags
}

resource "aws_security_group" "this" {
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingress" {
  count                    = length(var.ingress_ports)
  type                     = "ingress"
  from_port                = var.ingress_ports[count.index]
  to_port                  = var.ingress_ports[count.index]
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.source_security_group
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress" {
  count                    = length(var.ingress_ports)
  type                     = "egress"
  from_port                = var.ingress_ports[count.index]
  to_port                  = var.ingress_ports[count.index]
  protocol                 = "tcp"
  security_group_id        = var.source_security_group
  source_security_group_id = aws_security_group.this.id
  lifecycle {
    create_before_destroy = true
  }
}
