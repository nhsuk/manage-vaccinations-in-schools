resource "aws_vpc" "application_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-${var.environment_string}"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "public-subnet-${var.environment_string}-a"
  }
}


resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "public-subnet-${var.environment_string}-b"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "private-subnet-${var.environment_string}-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "private-subnet-${var.environment_string}-b"
  }
}

resource "aws_subnet" "nat_subnet_a" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "nat-subnet-${var.environment_string}-a"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.application_vpc.id
  tags = {
    Name = "igw-${var.environment_string}"
  }
}

################################# ROUTING #################################

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.application_vpc.id
  tags = {
    Name = "public-rt-${var.environment_string}"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.application_vpc.id
  tags = {
    Name = "private-rt-${var.environment_string}"
  }
}


resource "aws_route" "private_to_nat" {
  count                  = var.enable_firewall ? 0 : 1
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route" "private_to_firewall" {
  count                  = var.enable_firewall ? 1 : 0
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = module.firewall[0].firewall_endpoint_id
}

resource "aws_route" "igw_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "nat_subnet_a" {
  subnet_id      = aws_subnet.nat_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

################################# NAT/Firewall #################################

resource "aws_eip" "nat_ip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id         = aws_subnet.nat_subnet_a.id
  allocation_id     = aws_eip.nat_ip.id
  connectivity_type = "public"
  depends_on        = [aws_internet_gateway.internet_gateway]
}

module "firewall" {
  count                  = var.enable_firewall ? 1 : 0
  source                 = "./modules/firewall"
  vpc_id                 = aws_vpc.application_vpc.id
  firewall_subnet_cidr   = var.firewall_subnet_cidr
  retain_logs            = local.is_production
  environment_string     = var.environment_string
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  private_route_table_id = aws_route_table.private_route_table.id
  log_retention_days     = var.firewall_log_retention_days
  ecs_security_group_id  = aws_security_group.ecs_service_sg.id
}
