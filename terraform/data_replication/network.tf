resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table_association" "private" {
  count          = length(local.subnet_list)
  route_table_id = aws_route_table.private.id
  subnet_id      = local.subnet_list[count.index]
}

locals {
  vpc_endpoints = tomap(
    {
      ecr_api        = "com.amazonaws.${var.region}.ecr.api"
      ecr_docker     = "com.amazonaws.${var.region}.ecr.dkr"
      secretsmanager = "com.amazonaws.${var.region}.secretsmanager"
      cloudwatch     = "com.amazonaws.${var.region}.logs"
      ssm            = "com.amazonaws.${var.region}.ssm"
      ssmmessages    = "com.amazonaws.${var.region}.ssmmessages"
      rds            = "com.amazonaws.${var.region}.rds"
    }
  )
}

module "vpc_endpoints" {
  for_each              = local.vpc_endpoints
  source                = "../app/modules/vpc_endpoint"
  service_name          = each.value
  vpc_id                = aws_vpc.vpc.id
  subnet_ids            = local.subnet_list
  ingress_ports         = [443]
  source_security_group = module.db_access_service.security_group_id

  tags = {
    Name = "${local.name_prefix}-${each.key}-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags = {
    Name = "${local.name_prefix}-s3-gw-endpoint"
  }
}
