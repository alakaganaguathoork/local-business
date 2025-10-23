# Notes

## Prometheus

```bash
helm upgrade --install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace --values kubernetes/helm/helpers/prometheus/prom-custom-values-aws.yaml
```

## Node Exporter

```bash
helm upgrade --install prom-node-exporter prometheus-community/prometheus-node-exporter --namespace monitoring
```

```yaml
extraScrapeConfigs: |
  - job_name: 'local-business-pods'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ["app"]
    relabel_configs:
      # keep only pods with label app.kubernetes.io/name=myapp
      - action: keep
        source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
        regex: local-business
      # keep containers that expose a port named "metrics"
      # - action: keep
        # source_labels: [__meta_kubernetes_pod_container_port_name]
        # regex: metrics
      # set address to <podIP>:<containerPort> (covers IPv4/IPv6)
      - action: replace
        source_labels: [__meta_kubernetes_pod_ip, __meta_kubernetes_pod_container_port_number]
        target_label: __address__
        regex: (.+);(.+)
        replacement: $1:$2
    metrics_path: /metrics
    scheme: http
```
