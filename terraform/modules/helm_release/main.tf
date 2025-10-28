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
      name      = "monitoring"
      namespace = "monitoring"
      annotations = {
        "kubernetes.io/ingress.class"           = "alb"
        "alb.ingress.kubernetes.io/group.name"  = "shared-alb"
        "alb.ingress.kubernetes.io/group.order" = "40"
        "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
        "alb.ingress.kubernetes.io/target-type" = "ip"

        "alb.ingress.kubernetes.io/healthcheck-path" = "/"
        "alb.ingress.kubernetes.io/success-codes"    = "200,302" # Prometheus:200, Grafana:302 (login redirect)

        "alb.ingress.kubernetes.io/listen-ports"  = "[{\"HTTP\":80},{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/ssl-redirect"  = "443"
        "alb.ingress.kubernetes.io/inbound-cidrs" = "91.198.233.56/32"

        # "alb.ingress.kubernetes.io/healthcheck-path"   = "/-/healthy" #works for prometheus only
      }
    }
    spec = {
      ingressClassName = "alb"
      rules = [
        {
          host = "prometheus.mishap.local"
          http = {
            paths = [{
              path     = "/"
              pathType = "Prefix"
              backend = {
                service = {
                  name = "prometheus-server"
                  port = { number = 80 }
                }
              }
            }]
          }
        },
        {
          host = "grafana.mishap.local"
          http = {
            paths = [{
              path     = "/"
              pathType = "Prefix"
              backend = {
                service = {
                  name = "grafana"
                  port = { number = 80 }
                }
              }
            }]
          }
        },
        {
          host = "loki.mishap.local"
          http = {
            paths = [{
              path     = "/"
              pathType = "Prefix"
              backend = {
                service = {
                  name = "loki"
                  port = { number = 3100 }
                }
              }
            }]
          }
        }
      ]
    }
  }

  depends_on = [helm_release.this]
}
