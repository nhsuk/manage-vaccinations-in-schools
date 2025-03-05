# Firewall Subnets
resource "aws_subnet" "firewall" {
  for_each = { for idx, az in local.azs : az => local.subnet_cidrs[idx] }

  vpc_id            = var.vpc_id
  cidr_block        = each.value
  availability_zone = each.key
  tags = {
    Name = "firewall-subnet-${var.environment}-${each.key}"
  }
}

resource "aws_route_table" "firewall" {
  for_each = aws_subnet.firewall

  vpc_id = var.vpc_id
  tags = {
    Name = "firewall-rt-${var.environment}-${each.key}"
  }
}

resource "aws_route_table_association" "firewall" {
  for_each = aws_subnet.firewall

  subnet_id      = each.value.id
  route_table_id = aws_route_table.firewall[each.key].id
}

resource "aws_route" "firewall_to_nat" {
  for_each = aws_route_table.firewall

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_ids[each.key]
}
