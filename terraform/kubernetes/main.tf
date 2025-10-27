###
## Setup ingressClass for services
###

data "aws_subnets" "public" {
  filter {
    name   = "tag:\"kubernetes.io/cluster/${local.cluster_name}\""
    values = ["owned"]
  }

  filter {
    name   = "tag:Name"
    values = ["public-subnet-${local.cluster_name}"]
  }
}

module "tls_certificate" {
  source = "../modules/certificate"

  region                             = local.region
  generate_new_certificate           = true
  private_key_algorithm_ca           = "RSA"
  private_key_algorithm_cert_request = "RSA"
  dns_names                          = ["*.mishap.local", "mishap.local"]


  self_signed_cert_subject_ca = {
    common_name  = "MishaP Root CA"
    organization = "alakaganaguathoork"
    country      = "UA"
  }
}

module "ingress" {
  source = "../modules/ingress"

  subnet_ids = data.aws_subnets.public.ids
  tls_certificate_arn = module.tls_certificate.arn
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
