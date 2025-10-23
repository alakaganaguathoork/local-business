output "release" {
  value = { for value in helm_release.this : value.name => {
    id   = value.id
    name = value.name
    }
  }
}
