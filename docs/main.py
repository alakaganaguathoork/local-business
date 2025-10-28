# https://diagrams.mingrammer.com/

from diagrams import Diagram, Cluster, Edge

from diagrams.onprem.client import Users
from diagrams.onprem.gitops import ArgoCD
from diagrams.onprem.monitoring import Prometheus, Grafana
from diagrams.onprem.logging import Loki

from diagrams.aws.general import InternetAlt1
from diagrams.aws.network import ALB, IGW, PublicSubnet
from diagrams.aws.compute import EKS, EC2AutoScaling, EC2

from diagrams.k8s.ecosystem import Helm
from diagrams.k8s.network import Ingress, Service as K8sService
from diagrams.k8s.compute import Deployment, Pod
from diagrams.k8s.compute import RS as ReplicaSet

graph_attrs = {
    # "rankdir": "TB",      # Top -> Bottom
    # "splines": "spline",  # Curved splines (edges can attach from any side)
    "nodesep": "0.6",
    "ranksep": "0.9",
    "pad": "0.2",
    "newrank": "true",
    "bgcolor": "white",
}
node_attrs = {
    "fontsize": "14",
    "color": "gray50",
    "fontcolor": "black",
}
# Define a standard black edge for clean arrows
black_edge = Edge(color="black", style="solid")

with Diagram(
    "Local Business",
    filename="architecture",
    outformat="png",
    show=False,
    graph_attr=graph_attrs,
    node_attr=node_attrs,
):
    
    # ---------------- AWS ----------------
    user = Users("User")
    net = InternetAlt1("Internet")

    user >> Edge(color="black") >> net
    
    with Cluster("AWS"):
        with Cluster("VPC"):
            igw = IGW("IGW")
            alb = ALB("ALB (shared)")
            
            net >> Edge(color="black") >> igw >> Edge(color="black") >> alb 

            # ---------------- EKS ----------------
            with Cluster("EKS", direction="LR"):
                eks = EKS("EKS")
                asg = EC2AutoScaling("auto-scaler")

                eks >> Edge(color="black") >> asg

                # ---------------- Availability zone us-east-1a ----------------
                with Cluster("us-east-1a"):
                    p_subnet_1  = PublicSubnet("10.0.0.1/24")
                    node_1 = EC2("node 1")

                    with Cluster("monitoring namespace", direction="LR") as monitoring_cl:
                        ing_monitor = Ingress("prometheus-server\n/ grafana")
                        prom = Prometheus("Prometheus")
                        loki = Loki("Loki")
                        grafana = Grafana("Grafana")

                        ing_monitor >> Edge(color="black") >> [prom, grafana]

                    with Cluster("argocd namespace", direction="LR") as argocd_cl:
                        ing_argocd = Ingress("argocd")
                        argocd = ArgoCD("ArgoCD")
                        ing_argocd >> Edge(color="black") >> argocd

                        prom >> Edge(style="dashed", color="gray50") >> grafana << Edge(style="dashed", color="gray50") << loki

                    ing_argocd << Edge(color="black") << p_subnet_1 >> Edge(color="black") >> ing_monitor 

                # ---------------- Availability zone us-east-1b ----------------
                with Cluster("us-east-1b"):
                    p_subnet_2  = PublicSubnet("10.0.0.2/24")
                    node_2 = EC2("node 2")

                    with Cluster("app namespace", direction="LR"):
                        app = Helm("Application")
                        ing_app = Ingress("local-business")
                        svc_app = K8sService("svc")
                        dep_app = Deployment("deployment")
                        rs_app = ReplicaSet("ReplicaSet")
                        pod_a = Pod("pod-0")
                        pod_b = Pod("pod-1")
                        pod_c = Pod("pod-2")

                        app >> Edge(color="black") >> ing_app 
                        ing_app >> Edge(color="black") >> svc_app >> Edge(color="black") >> dep_app >> Edge(color="black") >> rs_app
                        rs_app >> Edge(style="dashed", color="gray50") >> [pod_c, pod_b, pod_a]

                    p_subnet_2 >> Edge(color="black") >> Edge(color="black") >> ing_app
                
                asg >> Edge(color="black") >> [node_1, node_2]

        alb >> Edge(color="black") >> [p_subnet_1, p_subnet_2]