data "http" "custom_values" {
  url             = var.release.values_file_url
  request_headers = { Accept = "text/yaml" }
}

resource "helm_release" "this" {
  name             = var.release.name
  namespace        = var.release.namespace
  repository       = var.release.repository
  chart            = var.release.chart
  create_namespace = try(var.release.create_namespace, true)
  cleanup_on_fail  = try(var.release.cleanup_on_fail, true)
  atomic           = try(var.release.atomic, true)
  force_update     = try(var.release.force_update, true)
  lint             = try(var.release.lint, true)
  replace          = true
  reuse_values     = true
  skip_crds        = true
  version          = try(var.release.version, null)
  values           = [data.http.custom_values.response_body]

  depends_on = [data.http.custom_values]
}

resource "kubernetes_manifest" "custom_ingress" {
  count = var.release.create_ingress ? 1 : 0

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "${var.release.name}-server"
      namespace = "${var.release.namespace}"
      annotations = {
        "kubernetes.io/ingress.class"                = "alb"
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\":80}]"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/-/healthy" # Needs to be adjusted
        # If you’re sharing one ALB across apps:
        # "alb.ingress.kubernetes.io/group.name"   = "shared-alb"
        # "alb.ingress.kubernetes.io/group.order"  = "10"
      }
    }
    spec = {
      ingressClassName = "alb"
      rules = [{
        http = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "${var.release.name}-server"
                port = { number = 80 }
              }
            }
          }]
        }
      }]
    }
  }

  depends_on = [helm_release.this]
}
