resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "data-replication-vpc-${var.environment}"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Private = true
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"
  tags = {
    Private = true
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "data-replication-private-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(local.subnet_list)
  route_table_id = aws_route_table.private.id
  subnet_id      = local.subnet_list[count.index]
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Private = false
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "data-replication-igw-${var.environment}"
  }
}

resource "aws_eip" "this" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  subnet_id         = aws_subnet.public_subnet.id
  allocation_id     = aws_eip.this.id
  connectivity_type = "public"
  depends_on        = [aws_internet_gateway.this]
  tags = {
    Name = "data-replication-nat-gateway-${var.environment}"
  }
}

resource "aws_route" "private_to_public" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "public_to_igw" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "data-replication-public-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_subnet.id
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
