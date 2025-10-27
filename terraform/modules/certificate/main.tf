resource "null_resource" "gen_wildcard" {
  count = !var.generate_new_certificate ? 1 : 0
  # triggers = {
    # script_sha = filesha256("${path.module}/scripts/genererate-tls-cert.sh")
    # rotate_at  = ""
  # }

  provisioner "local-exec" {
    command = "${path.root}/scripts/generate-tls-cert.sh"
  }
}

# providers
terraform {
  required_providers {
    tls = { source = "hashicorp/tls" }
  }
}
provider "aws" { region = var.region }

# --- CA ---
resource "tls_private_key" "ca" {
  count = var.generate_new_certificate ? 1 : 0

  algorithm = var.private_key_algorithm_ca
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  count = var.generate_new_certificate ? 1 : 0

  private_key_pem       = tls_private_key.ca.private_key_pem
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
resource "tls_private_key" "wildcard" {
  count = var.generate_new_certificate ? 1 : 0

  algorithm = var.private_key_algorithm_cert_request
  rsa_bits  = 2048
}

resource "tls_cert_request" "wildcard" {
  count = var.generate_new_certificate ? 1 : 0

  private_key_pem = tls_private_key.wildcard.private_key_pem
  # subject {
  # common_name  = "*.mishap.local" # any test name is fine
  # organization = "alakaganaguathoork"
  # country      = "UA"
  # }
  dns_names = var.dns_names
}

resource "tls_locally_signed_cert" "wildcard" {
  count = var.generate_new_certificate ? 1 : 0

  cert_request_pem      = tls_cert_request.wildcard.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 397 * 24

  allowed_uses = ["server_auth", "client_auth", "digital_signature", "key_encipherment"]
}

###
## Import to ACM
###
resource "aws_acm_certificate" "self" {
  count = !var.generate_new_certificate ? 1 : 0

  private_key      = file("${path.module}/scripts/generated-certs/private/ca.key")
  certificate_body = file("${path.module}/scripts/generated-certs/certs/all.crt")

  depends_on = [null_resource.gen_wildcard]
}

# --- Import leaf into ACM (same region/account as your ALB) ---
resource "aws_acm_certificate" "wildcard" {
  count = var.generate_new_certificate ? 1 : 0

  private_key      = tls_private_key.wildcard.private_key_pem
  certificate_body = tls_locally_signed_cert.wildcard.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

output "acm_self_arn" {
  value = aws_acm_certificate.self.arn
}


output "acm_wildcard_arn" {
  value = aws_acm_certificate.wildcard.arn
}
