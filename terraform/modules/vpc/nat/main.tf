locals {
  public_subnets  = { for idx, subnet in var.public_subnets : idx => subnet }
  private_subnets = { for idx, subnet in var.private_subnets : idx => subnet }
}

resource "aws_eip" "nat-eip" {
  for_each = local.public_subnets

  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  for_each = local.public_subnets

  subnet_id     = each.value.id
  allocation_id = aws_eip.nat-eip[each.key].id
}

resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.nat

  vpc_id = var.vpc_id
}

resource "aws_route" "private" {
  for_each = aws_nat_gateway.nat

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = each.value.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = { for idx, subnet in var.private_subnets : idx => subnet }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
