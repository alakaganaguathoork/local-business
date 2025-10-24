resource "kubernetes_manifest" "alb_params" {
  manifest = {
    # apiVersion = "eks.amazonaws.com/v1"
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "IngressClassParams"
    metadata   = { name = "alb" }
    spec = {
      # Required/commonly used
      scheme = "internet-facing" # or "internal"
      subnets = { ids = var.subnet_ids }
      ipAddressType = "ipv4"
      group = {
        name = "shared-alb"
      }
      # Optional: ACM certs for HTTPS
      # certificateARNs = [
      #   "arn:aws:acm:REGION:ACCOUNT:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
      # ]

      # Optional: extra AWS tags on created resources (LIST of {key,value})
      # tags = [
      # { key = "Type", value = "shared" }
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
