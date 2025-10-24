resource "kubernetes_manifest" "alb_params" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"
    
    metadata   = { 
      name = "shared-alb" 
      }

    spec = {
      # Required/commonly used
      scheme        = "internet-facing" # or "internal"
      subnets       = { ids = var.subnet_ids }
      ipAddressType = "ipv4"

      group = {
        "name" = "shared-alb"
      }

      # Optional: ACM certs for HTTPS
      certificateARNs = [
        "arn:aws:acm:us-east-1:838062310110:certificate/e002b877-ce84-4af4-b696-48853ef46739"
      ]

      # Optional: extra AWS tags on created resources (LIST of {key,value})
      # tags = [
      # { key = "App", value = "argocd" }
      # ]

      # Optional: ALB attributes (LIST of {key,value})
      # loadBalancerAttributes = [
      #   { key = "idle_timeout.timeout_seconds", value = "60" }
      # ]
    }
  }
}

# IngressClass that tells K8s to use EKS Auto Mode’s ALB controller
resource "kubernetes_ingress_class_v1" "alb" {
  metadata {
    name = "alb"
    annotations = {
      "alb.ingress.kubernetes.io/group.name" = "shared-alb"
    }
  }
  spec {
    controller = "eks.amazonaws.com/alb"
    parameters {
      api_group = "eks.amazonaws.com"
      kind      = "IngressClassParams"
      name      = kubernetes_manifest.alb_params.object.metadata.name
    }
  }
}

resource "kubernetes_manifest" "custom_ingress" {
  count = var.release.create_ingress ? 1 : 0

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "shared"
      namespace = "monitoring"
      annotations = {
        # "kubernetes.io/ingress.class"                  = "alb"
        # "alb.ingress.kubernetes.io/load-balancer-name" = "shared-alb"
        # "alb.ingress.kubernetes.io/group.name"         = "shared-alb"
        # "alb.ingress.kubernetes.io/group.order"        = "10"
        # "alb.ingress.kubernetes.io/target-type"        = "ip"
        # "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTP\":80},{\"HTTPS\":443}]"
        # "alb.ingress.kubernetes.io/healthcheck-path"   = "/-/healthy"
        # "alb.ingress.kubernetes.io/certificate-arn"    = "arn:aws:acm:us-east-1:838062310110:certificate/e002b877-ce84-4af4-b696-48853ef46739"
      }
    }
    spec = {
      ingressClassName = "alb"
      rules = [{
        http = {
          paths = [{
            path     = "/grafana"
            pathType = "Prefix"
            backend = {
              service = {
                name = "grafana"
                port = { number = 80 }
              }
            },
            path     = "/prometheus"
            pathType = "Prefix"
            backend = {
              service = {
                name = "prometheus-server"
                port = { number = 80 }
              }
            }
          }]
        }
      }]
    }
  }
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata { name = "gp3" }
  storage_provisioner    = "ebs.csi.eks.amazonaws.com" # Auto Mode
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}