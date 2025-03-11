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
      version = "2.36.0"
    }
    proxmox = {
      source = "bpg/proxmox"
      version = "0.73.1"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.7.1"
    }
  }
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}

provider "helm" {
  kubernetes {
    host                    = module.kubernetes.kubeconfig.kubernetes_client_configuration.host
    client_certificate      = base64decode(module.kubernetes.kubeconfig.kubernetes_client_configuration.client_certificate)
    client_key              = base64decode(module.kubernetes.kubeconfig.kubernetes_client_configuration.client_key)
    cluster_ca_certificate  = base64decode(module.kubernetes.kubeconfig.kubernetes_client_configuration.ca_certificate)
  }
}

provider "kubernetes" {
  host                    = module.kubernetes.kubeconfig.kubernetes_client_configuration.host
  client_certificate      = base64decode(module.kubernetes.kubeconfig.kubernetes_client_configuration.client_certificate)
  client_key              = base64decode(module.kubernetes.kubeconfig.kubernetes_client_configuration.client_key)
  cluster_ca_certificate  = base64decode(module.kubernetes.kubeconfig.kubernetes_client_configuration.ca_certificate)
  ignore_labels = [
    "app.kubernetes.io/.*",
    "kustomize.toolkit.fluxcd.io/.*",
  ]
}

provider "proxmox" {
  endpoint = "https://${var.proxmox_ip}:8006/"
  insecure = true
}
