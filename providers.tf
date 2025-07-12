terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.8.1"
    }
  }
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}

provider "helm" {
  kubernetes {
    host                    = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
    client_certificate      = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key              = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
    cluster_ca_certificate  = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  }
}

provider "kubernetes" {
  host                    = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
  client_certificate      = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
  client_key              = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  cluster_ca_certificate  = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  ignore_labels = [
    "app.kubernetes.io/.*",
    "kustomize.toolkit.fluxcd.io/.*",
  ]
}
