locals {
  env = "test"
  region = "us-east-1"
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
    }
    grafana = {
      values_file_url = "https://raw.githubusercontent.com/alakaganaguathoork/local-business/refs/heads/main/helm/helpers/grafana/grafana-custom-values-aws.yaml"
      name            = "grafana"
      namespace       = "monitoring"
      repository      = "https://grafana.github.io/helm-charts"
      chart           = "grafana"
    }
  }
}