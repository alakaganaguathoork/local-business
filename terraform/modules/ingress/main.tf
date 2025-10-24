resource "kubernetes_manifest" "alb_params" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"
    metadata   = { name = "alb" }
    spec = {
      # Required/commonly used
      scheme = "internet-facing" # or "internal"
      subnets = { ids = var.subnet_ids }
      ipAddressType = "ipv4"

      # Optional: ACM certs for HTTPS
      # certificateARNs = [
      #   "arn:aws:acm:REGION:ACCOUNT:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
      # ]

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
  metadata { name = "alb" }
  spec {
    controller = "eks.amazonaws.com/alb"
    parameters {
      api_group = "eks.amazonaws.com"
      kind      = "IngressClassParams"
      name      = kubernetes_manifest.alb_params.object.metadata.name
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

