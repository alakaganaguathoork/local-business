variable "region" {
  type = string
}

variable "generate_new_certificate" {
  type        = optional(bool)
  default     = true
  description = "If false, you should provide your own externally generated certificate. Default is `true`."
}

variable "private_key_algorithm_ca" {
  type        = optinal(string)
  default     = "RSA"
  description = "Algorithm to use to generate a CA private key"

  validation {
    condition = contains("RSA", "ECDSA", "ED25519", var.private_key_algorithm_ca)

    error_message = "Should match any of three: `RSA`, `ECDSA`, `ED25519`."
  }
}

variable "self_signed_cert_subject_ca" {
  type = optinal(object({
    common_name  = string
    organization = string
    country      = string
  }))
}

variable "private_key_algorithm_cert_request" {
  type        = optional(string)
  default     = "RSA"
  description = "Algorithm to use to generate a wildcard private key"

  validation {
    condition = contains("RSA", "ECDSA", "ED25519", var.private_key_algorithm_cert_request)

    error_message = "Should match any of three: `RSA`, `ECDSA`, `ED25519`."
  }
}

variable "dns_names" {
  type = optinal(list(string))
  default = []
}

