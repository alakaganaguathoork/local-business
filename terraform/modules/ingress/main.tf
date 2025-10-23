resource "kubernetes_manifest" "alb_params" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"
    metadata   = { name = "alb" }
    spec = {
      # Required/commonly used
      scheme = "internet-facing" # or "internal"

      # Optional: choose one of these subnet selectors
      # (A) explicit subnet IDs
      subnets = { ids = var.subnet_ids }

      # (B) tag-based selection (note: matchTags is a LIST of {key,value})
      # subnets = {
      # matchTags = [
      # { key = "kubernetes.io/role/elb", value = "1" },
      # { key = "kubernetes.io/cluster/${var.cluster.name}", value = "owned" }
      # ]
      # }

      # Optional: ALB IP mode
      # ipAddressType = "dualstack"  # or "ipv4"

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
