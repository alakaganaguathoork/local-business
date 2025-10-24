# Notes

1. Install

    ```bash
    helm upgrade --install grafana grafana/grafana --namespace monitoring --create-namespace --values kubernetes/helm/helpers/grafana/grafana-custom-values-local.yaml
    ```

2. Add Ingress Hostname:

   ```bash
   kubectl get ingress grafana -n monitoring -o jsonpath="{.status.loadBalancer.ingress[*].hostname}" ; echo
   ```

3. Add dashboards:

    ```bash
    kubectl create configmap local-business-dashboard \
                    -n monitoring \
                    --from-file=main.json=monitoring/grafana/dashboards/main.json \
                    -o yaml --dry-run=client | kubectl apply -f -
                  kubectl label configmap -n monitoring local-business-dashboard grafana_dashboard=1 --overwrite
                  kubectl label configmap -n monitoring local-business-dashboard grafana_folder="Local_Business" --overwrite
    ```
