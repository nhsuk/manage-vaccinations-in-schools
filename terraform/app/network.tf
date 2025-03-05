resource "aws_vpc" "application_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-${var.environment}"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "public-subnet-${var.environment}-a"
  }
}


resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "public-subnet-${var.environment}-b"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "private-subnet-${var.environment}-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "private-subnet-${var.environment}-b"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.application_vpc.id
  tags = {
    Name = "igw-${var.environment}"
  }
}

################################# ROUTING #################################

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.application_vpc.id
  tags = {
    Name = "public-rt-${var.environment}"
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.application_vpc.id
  tags = {
    Name = "private-rt-${var.environment}-a"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.application_vpc.id
  tags = {
    Name = "private-rt-${var.environment}-b"
  }
}


resource "aws_route" "private_to_firewall_a" {
  count                  = var.enable_firewall ? 1 : 0
  route_table_id         = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = module.firewall[0].firewall_endpoint_ids["eu-west-2a"]
}

resource "aws_route" "private_to_firewall_b" {
  count                  = var.enable_firewall ? 1 : 0
  route_table_id         = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = module.firewall[0].firewall_endpoint_ids["eu-west-2b"]
}

resource "aws_route" "private_to_nat_a" {
  count                  = var.enable_firewall ? 0 : 1
  route_table_id         = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_a.id
}

resource "aws_route" "private_to_nat_b" {
  count                  = var.enable_firewall ? 0 : 1
  route_table_id         = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_b.id
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
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_b.id
}

################################# NAT/Firewall #################################

resource "aws_eip" "nat_ip_a" {
  domain = "vpc"
}
# NAT Gateway in eu-west-2b (new)

resource "aws_eip" "nat_ip_b" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway_a" {
  subnet_id         = aws_subnet.public_subnet_a.id  # Public subnet in eu-west-2a
  allocation_id     = aws_eip.nat_ip_a.id
  connectivity_type = "public"
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway_b" {
  subnet_id = aws_subnet.public_subnet_b.id  # Public subnet in eu-west-2b
  allocation_id     = aws_eip.nat_ip_b.id
  connectivity_type = "public"
  depends_on = [aws_internet_gateway.internet_gateway]
}

module "firewall" {
  count                  = var.enable_firewall ? 1 : 0
  source                 = "./modules/firewall"
  vpc_id                 = aws_vpc.application_vpc.id
  firewall_subnet_cidr   = var.firewall_subnet_cidr
  retain_logs            = local.is_production
  environment            = var.environment
  nat_gateway_ids         = {
    "eu-west-2a" = aws_nat_gateway.nat_gateway_a.id
    "eu-west-2b" = aws_nat_gateway.nat_gateway_b.id
  }
  log_retention_days     = var.firewall_log_retention_days
}
