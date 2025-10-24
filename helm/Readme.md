# Notes

* Install ArgoCD with LoadBalancer service type:

    ```bash
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm install argocd argo/argo-cd -n argocd --create-namespace --set server.service.type=LoadBalancer
    ```

* Get Service endpoint:

    ```bash
    SERVICE_IP=$(kubectl get svc -n <namespace> <service-name> -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    echo $SERVICE_IP
    ```

* Get ArgoCD admin password:

    ```bash
    ARGOCD_ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo $ARGOCD_ADMIN_PASSWORD
    ```

* Port forward ArgoCD server:

    ```bash
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```

* Upgrade ArgoCD:

    ```bash
    helm upgrade argocd argo/argo-cd -n argocd
    ```

* Save EKS security group IDs to a file:

    ```bash
    terraform output -raw eks_sg_ids | tr -d '[]" ' | tr ',' '\n' > .sg-ids.output
    ```
