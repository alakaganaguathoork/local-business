output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

# output "public_subnets_count" {
# value = aws_subnet.public_subnet_count
# }
# 
# output "private_subnet_count" {
# value = aws_subnet.private_subnet_count
# }

output "public_subnets" {
  value       = aws_subnet.defined_public_subnet
  description = "List of created public subnets objects"
}

output "private_subnets" {
  value = aws_subnet.defined_private_subnet
}

output "security_groups" {
  value = module.security_groups.groups
}
