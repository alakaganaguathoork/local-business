locals {
  env          = "test"
  region       = "us-east-1"
  cluster_name = "sandbox"

  helm_releases = {
    argocd = {
      values_file_url = "https://raw.githubusercontent.com/alakaganaguathoork/local-business/refs/heads/main/helm/helpers/argocd/argocd-custom-values-aws.yaml"
      name            = "argocd"
      namespace       = "argocd"
      repository      = "https://argoproj.github.io/argo-helm"
      chart           = "argo-cd"
    }
    prometheus = {
      values_file_url = "https://raw.githubusercontent.com/alakaganaguathoork/local-business/refs/heads/main/helm/helpers/prometheus/prom-custom-values-aws.yaml"
      name            = "prometheus"
      namespace       = "monitoring"
      repository      = "https://prometheus-community.github.io/helm-charts"
      chart           = "prometheus"
      create_ingress  = true
    }
    grafana = {
      values_file_url = "https://raw.githubusercontent.com/alakaganaguathoork/local-business/refs/heads/main/helm/helpers/grafana/grafana-custom-values-aws.yaml"
      name            = "grafana"
      namespace       = "monitoring"
      repository      = "https://grafana.github.io/helm-charts"
      chart           = "grafana"
    }
    loki = {
      values_file_url = "https://raw.githubusercontent.com/alakaganaguathoork/local-business/refs/heads/main/helm/helpers/loki/loki-custom-values-aws.yaml"
      name            = "loki"
      namespace       = "monitoring"
      repository      = "https://grafana.github.io/helm-charts"
      chart           = "loki"
    }
    alloy = {
      values_file_url = "https://raw.githubusercontent.com/alakaganaguathoork/local-business/refs/heads/main/helm/helpers/alloy/alloy-custom-values-aws.yaml"
      name            = "alloy"
      namespace       = "monitoring"
      repository      = "https://grafana.github.io/helm-charts"
      chart           = "alloy"
    }
  }
}
