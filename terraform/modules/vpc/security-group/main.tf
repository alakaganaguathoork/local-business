resource "aws_security_group" "sg" {
  for_each = var.security_groups

  name   = each.key
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "rule" {
  for_each = local.sg_rules

  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.sg[each.value.sg_name].id
  self                     = try(each.value.self, null)
  cidr_blocks              = try(each.value.cidr_blocks, null)
  source_security_group_id = try(aws_security_group.sg[each.value.source_security_group_name].id, null)
  description              = try(each.value.description, null)
}
