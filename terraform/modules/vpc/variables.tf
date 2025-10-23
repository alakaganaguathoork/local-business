variable "environment" {
  type        = string
  description = "Environment for networking"
}

variable "vpc_cidr_block" {
  type = string
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Allow VPC to create DNS records"
}

variable "public_subnets_count" {
  type        = number
  description = "Count of public subnets to create with allocated CIDR blocks within defined VPC"
  default     = 0
}

variable "private_subnets_count" {
  type        = number
  description = "Count of private subnets to create with allocated CIDR blocks within defined VPC"
  default     = 0
}

variable "public_subnets" {
  type        = list(string)
  description = "List of predefined public subnets CIDR block"
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.public_subnets : can(cidrnetmask(cidr))
    ])
    error_message = "Subnet's CIDR block should conform a valid netmask '10.0.0.0/16'"
  }
}

variable "private_subnets" {
  type        = list(string)
  description = "List of predefined private subnets CIDR block"
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.private_subnets : can(cidrnetmask(cidr))
    ])
    error_message = "Subnet's CIDR block should conform a valid netmask '10.0.0.0/16'"
  }
}

variable "enable_nat" {
  type = bool
}

variable "enable_gateway" {
  type = bool
}

variable "security_groups" {
  type = any
}

variable "create_secretmanager_endpoint" {
  type        = bool
  description = "Instruct to create a private endpoint to the AWS Secret Manager service in order to retrieve and rotate secrets within VPC only"
  default     = false
}
