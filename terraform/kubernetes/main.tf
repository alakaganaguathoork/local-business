###
## Setup ingressClass for services
###

data "aws_subnets" "public" {
  filter {
    name = "tag:\"kubernetes.io/cluster/${local.cluster_name}\""
    values = [ "owned" ]
  }

  filter {
    name = "tag:Name"
    values = [ "public-subnet-${local.cluster_name}" ]
  }
}

module "ingress" {
  source = "../modules/ingress"

  subnet_ids = data.aws_subnets.public.ids
}

###
## Install services
###
module "helm_releases" {
  for_each = local.helm_releases

  source = "../modules/helm_release"

  release = each.value

  depends_on = [module.ingress]
}