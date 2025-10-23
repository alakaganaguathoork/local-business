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
      project = "eks-automode"
    }
  }
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Environment = local.env
    }
  }
}

# provider "kubernetes" {
  # config_path = "~/.kube/config"
# }