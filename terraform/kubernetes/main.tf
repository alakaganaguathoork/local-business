###
## Setup ingressClass for services
###

data "aws_subnets" "public" {
}

module "ingress" {
  source = "../modules/ingress"

  subnet_ids = data.aws_subnet.public.ids

  depends_on = [aws_eks_cluster.main]
}

###
## Install services
###
module "helm_releases" {
  for_each = local.helm_releases

  source = "../modules/helm_release"

  helm_release = each.value

  depends_on = [module.ingress]
}
