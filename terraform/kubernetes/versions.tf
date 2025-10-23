terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.13.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.0.2"
    }
  }

  cloud {
    organization = "alakaganaguathoork"
    
    workspaces {
      name = "test"
      project = "kubernetes"
    }
  }
}

data "aws_eks_cluster" "main" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = local.cluster_name
}

data "aws_caller_identity" "current" {
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  # exec {
    # api_version = "client.authentication.k8s.io/v1beta1"
    # args        = ["eks", "get-token", "--cluster-name", var.cluster.name]
    # command     = "aws"
  # }
  token = data.aws_eks_cluster_auth.main.token
}


provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    # exec = {
      # api_version = "client.authentication.k8s.io/v1beta1"
      # args        = ["eks", "get-token", "--cluster-name", var.cluster.name]
      # command     = "aws"
    # }
    token = data.aws_eks_cluster_auth.main.token
  }
}