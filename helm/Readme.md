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

* Nice services output:

    ```bash
    kubectl get ingress -A -o json | \
    jq -r '
        def H: ["NAMESPACE","NAME","CLASS","HOST","PATH","SERVICE","PORT","ALB_GROUP","TARGET_TYPE","LISTEN_PORTS","LB_HOSTNAME"];
        (H | @tsv),
        (.items[] as $i
         | ($i.spec.rules[]? // [{"host":"*","http":$i.spec.defaultBackend|not}]) as $r
         | ($r.http.paths[]? // [{"path":"/*","backend":$i.spec.defaultBackend}] )
         | [
            $i.metadata.namespace,
            $i.metadata.name,
            ($i.spec.ingressClassName // $i.metadata.annotations["kubernetes.io/ingress.class"] // "-"),
            ($r.host // "*"),
            (.path // "/*"),
            (.backend.service.name // "-"),
            (.backend.service.port.number // .backend.service.port.name // "-"),
            ($i.metadata.annotations["alb.ingress.kubernetes.io/group.name"] // "-"),
            ($i.metadata.annotations["alb.ingress.kubernetes.io/target-type"] // "-"),
            ($i.metadata.annotations["alb.ingress.kubernetes.io/listen-ports"] // "-"),
            (($i.status.loadBalancer.ingress // []) | map(.hostname // .ip) | join(","))
          ] | @tsv
        )
    ' | \
    column -t -s $'\t'
    ```
