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

resource "kubernetes_manifest" "prom_ingress" {
  count = var.release.create_ingress ? 1 : 0

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "prometheus"
      namespace = "monitoring"
      annotations = {
        "kubernetes.io/ingress.class"                  = "alb"
        "alb.ingress.kubernetes.io/load-balancer-name" = "shared-alb"
        "alb.ingress.kubernetes.io/group.name"         = "shared-alb"
        "alb.ingress.kubernetes.io/group.order"        = "40"
        "alb.ingress.kubernetes.io/healthcheck-path"   = "/healthz"
        # "alb.ingress.kubernetes.io/target-type"        = "ip"
        "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80},{\"HTTPS\":443}]"
        # "alb.ingress.kubernetes.io/healthcheck-path"   = "/-/healthy"
        # "alb.ingress.kubernetes.io/certificate-arn"    = "arn:aws:acm:us-east-1:838062310110:certificate/e002b877-ce84-4af4-b696-48853ef46739"
      }
    }
    spec = {
      ingressClassName = "alb"
      rules = [{
        http = {
          paths = [
            {
              path     = "/"
              pathType = "Prefix"
              backend = {
                service = {
                  name = "prometheus-server"
                  port = { number = 80 }
                }
              }
            }
          ]
        }
      }]
    }
  }

  depends_on = [kubernetes_ingress_class_v1.shared_ingress]
}
