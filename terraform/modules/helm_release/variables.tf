variable "release" {
  type = object({
    values_file_url = string
    name            = string
    namespace       = string
    repository      = string
    chart           = string
    cleanup_on_fail = optional(bool)
    atomic          = optional(bool)
    force_update    = optional(bool)
    version         = optional(string)
  })
}
