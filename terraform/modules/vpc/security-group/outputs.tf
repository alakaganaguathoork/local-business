output "groups" {
  value = aws_security_group.sg
}

output "rules" {
  value = aws_security_group_rule.rule
}
