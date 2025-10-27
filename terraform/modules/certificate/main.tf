# providers
terraform {
  required_providers {
    tls = { source = "hashicorp/tls" }
  }
}

provider "aws" { region = var.region }

data "external" "cert" {
  count = var.generate_new_certificate ? 0 : 1
  program = ["bash", "-lc", "${path.module}/scripts/generate-cert.sh"]
}

# --- CA ---
resource "tls_private_key" "ca" {
  count = var.generate_new_certificate ? 1 : 0

  algorithm = var.private_key_algorithm_ca
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  count = var.generate_new_certificate ? 1 : 0

  private_key_pem       = tls_private_key.ca[count.index].private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 3650 * 24

  dynamic "subject" {
    for_each = var.self_signed_cert_subject_ca

    content {
      common_name  = each.value.common_name
      organization = each.value.organization
      country      = each.value.country
    }
  }

  allowed_uses = ["cert_signing", "crl_signing", "digital_signature", "key_encipherment"]
}

# --- Wildcard leaf signed by our CA ---
resource "tls_private_key" "leaf" {
  count = var.generate_new_certificate ? 1 : 0

  algorithm = var.private_key_algorithm_cert_request
  rsa_bits  = 2048
}

resource "tls_cert_request" "leaf" {
  count = var.generate_new_certificate ? 1 : 0

  private_key_pem = tls_private_key.leaf[count.index].private_key_pem
  subject {
    common_name = var.dns_names[0] # any test name is fine
  }
  dns_names = var.dns_names
}

resource "tls_locally_signed_cert" "leaf" {
  count = var.generate_new_certificate ? 1 : 0

  cert_request_pem      = tls_cert_request.leaf[count.index].cert_request_pem
  ca_private_key_pem    = tls_private_key.ca[count.index].private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca[count.index].cert_pem
  validity_period_hours = 397 * 24

  allowed_uses = ["server_auth", "client_auth", "digital_signature", "key_encipherment"]
}

###
## Import to ACM
###
resource "aws_acm_certificate" "imported" {
  count             = var.generate_new_certificate ? 0 : 1

  private_key       = base64decode(data.external.cert[0].result.private_key_b64)
  certificate_body  = base64decode(data.external.cert[0].result.certificate_b64)
  certificate_chain = base64decode(try(data.external.cert[0].result.chain_b64, ""))
}

resource "aws_acm_certificate" "generated" {
  count = var.generate_new_certificate ? 1 : 0

  private_key       = tls_private_key.leaf[count.index].private_key_pem
  certificate_body  = tls_locally_signed_cert.leaf[count.index].cert_pem
  certificate_chain = tls_self_signed_cert.ca[count.index].cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

output "arn" {
  value = coalesce(
    try(aws_acm_certificate.generated[0].arn, null),
    try(aws_acm_certificate.imported[0].arn, null)
  )
}
