resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.identifier}-vpc"
  }
}

resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-2c"
  tags = {
    Name = "${var.identifier}-subnet"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.identifier}-igw"
  }
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.identifier}-rt"
  }
}

resource "aws_route" "public_to_igw" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.this.id
  subnet_id      = aws_subnet.this.id
}
