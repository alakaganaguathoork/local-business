output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "subnet_ids" {
  value = aws_subnet.subnet[*].id
}

output "security_groups" {
  value = module.security-groups.groups[*]
}

output "oidc_issuer_url" {
  value = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "loki_role_arn" {
  value = aws_iam_role.loki.arn
}