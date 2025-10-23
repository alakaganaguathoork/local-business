locals {
  cluster_name = "sanbox"

  helm_releases = {
    argocd = {
      values_file_url = "https://raw.githubusercontent.com/alakaganaguathoork/local-business-open-api-project/refs/heads/main/kubernetes/helm/helpers/argocd/argocd-custom-values-aws.yaml"
      name            = "argocd"
      namespace       = "argocd"
      repository      = "https://argoproj.github.io/argo-helm"
      chart           = "argo-cd"
    }
    prometheus = {
      values_file_url = "https://raw.githubusercontent.com/alakaganaguathoork/local-business-open-api-project/refs/heads/main/kubernetes/helm/helpers/prometheus/prometheus-custom-values-aws.yaml"
      name            = "prometheus"
      namespace       = "monitoring"
      repository      = "https://prometheus-community.github.io/helm-charts"
      chart           = "prometheus-community/prometheus"
    }
    grafana = {
      values_file_url = "https://raw.githubusercontent.com/alakaganaguathoork/local-business-open-api-project/refs/heads/main/kubernetes/helm/helpers/grafana/grafana-custom-values-aws.yaml"
      name            = "grafana"
      namespace       = "monitoring"
      repositoty      = "https://grafana.github.io/helm-charts"
      chart           = "grafana/grafana"
    }
  }
}
