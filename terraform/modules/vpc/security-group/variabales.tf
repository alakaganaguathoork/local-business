variable "vpc_id" {
  type = string
}

variable "security_groups" {
  type = map(
    map(
      object({
        type                       = string
        from_port                  = number
        to_port                    = number
        protocol                   = string
        cidr_blocks                = optional(list(string))
        self                       = optional(bool)
        source_security_group_name = optional(string)
        description                = optional(string)
      })
    )
  )
}
