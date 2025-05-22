resource "aws_security_group" "dms" {
  name        = "dms-security-group"
  description = "Security group for DMS replication instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "dms-security-group-${var.environment}"
  }
}

module "secretsmanager_vpc_endpoint" {
  source                = "../vpc_endpoint"
  ingress_ports         = ["443"]
  service_name          = "com.amazonaws.eu-west-2.secretsmanager"
  source_security_group = aws_security_group.dms.id
  subnet_ids            = var.subnet_ids
  vpc_id                = var.vpc_id
  tags = {
    Name = "SecretsManager VPC Endpoint - ${var.environment}"
  }
}

resource "aws_security_group_rule" "egress_to_rds" {
  type                     = "egress"
  from_port                = var.source_port
  to_port                  = var.source_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dms.id
  source_security_group_id = var.rds_cluster_security_group_id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "dms_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.rds_cluster_security_group_id
  source_security_group_id = aws_security_group.dms.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_from_ecs" {
  count                    = length(var.ecs_sg_ids)
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.secretsmanager_vpc_endpoint.sg_id
  source_security_group_id = var.ecs_sg_ids[count.index]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress_to_ecs" {
  count                    = length(var.ecs_sg_ids)
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.ecs_sg_ids[count.index]
  source_security_group_id = module.secretsmanager_vpc_endpoint.sg_id
  lifecycle {
    create_before_destroy = true
  }
}
