variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "public_subnets" {
  type = any
}

variable "private_subnets" {
  type = any
}
