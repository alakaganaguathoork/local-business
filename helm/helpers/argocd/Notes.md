# Notes

1. Install using Helm chart

    ```bash
    helm upgrade --install argocd argo/argo-cd --namespace argocd --create-namespace --reuse-values --values ./argocd-custom-values-local.yaml
    ```

2. Get initial password

    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo
    ```

3. Set a custom admin password:

    ```bash
    ARGO_PWD='admin'
    EARGO_PWD=$(htpasswd -nbBC 10 "" "$ARGO_PWD" | tr -d ':\n' | sed 's/^\$2y/\$2a/') 

    kubectl -n argocd patch secret argocd-secret \
      --type merge \
      -p "$(jq -n --arg pwd "$EARGO_PWD" --arg mtime "$(date +%FT%T%Z)" \
          '{stringData: {"admin.password": $pwd, "admin.passwordMtime": $mtime}}')"
    ```
