resource "kubernetes_manifest" "alb" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"

    metadata = {
      name = "alb"
    }

    spec = {
      scheme        = "internet-facing" # or "internal"
      subnets       = { ids = var.subnet_ids }
      ipAddressType = "ipv4"

      group = {
        "name" = "shared-alb"
      }

      certificateARNs = [var.tls_certificate_arn]
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
      name      = kubernetes_manifest.alb.object.metadata.name
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
