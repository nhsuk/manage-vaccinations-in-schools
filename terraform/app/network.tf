resource "aws_vpc" "application_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-${var.environment}"
  }
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.application_vpc.id
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

resource "aws_subnet" "nat_subnet_a" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "nat-subnet-${var.environment}-a"
  }
}

resource "aws_subnet" "nat_subnet_b" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "nat-subnet-${var.environment}-b"
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

resource "aws_route_table" "private_route_table_a" {
  vpc_id = aws_vpc.application_vpc.id
  tags = {
    Name = "private-rt-${var.environment}-a"
  }
}

resource "aws_route_table" "private_route_table_b" {
  vpc_id = aws_vpc.application_vpc.id
  tags = {
    Name = "private-rt-${var.environment}-b"
  }
}


resource "aws_route" "private_to_nat_a" {
  route_table_id         = aws_route_table.private_route_table_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_a.id
}

resource "aws_route" "private_to_nat_b" {
  route_table_id         = aws_route_table.private_route_table_b.id
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
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table_b.id
}

resource "aws_route_table_association" "nat_subnet_a" {
  subnet_id      = aws_subnet.nat_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "nat_subnet_b" {
  subnet_id      = aws_subnet.nat_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

################################# NAT Gateway #################################

resource "aws_eip" "nat_ip_a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_eip" "nat_ip_b" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway_a" {
  subnet_id         = aws_subnet.nat_subnet_a.id
  allocation_id     = aws_eip.nat_ip_a.id
  connectivity_type = "public"
  depends_on        = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway_b" {
  subnet_id         = aws_subnet.nat_subnet_b.id
  allocation_id     = aws_eip.nat_ip_b.id
  connectivity_type = "public"
  depends_on        = [aws_internet_gateway.internet_gateway]
}
