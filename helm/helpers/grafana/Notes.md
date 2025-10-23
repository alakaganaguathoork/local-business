# Notes

1. Install

    ```bash
    helm upgrade --install grafana grafana/grafana --namespace monitoring --create-namespace --values kubernetes/helm/helpers/grafana/grafana-custom-values-local.yaml
    ```
