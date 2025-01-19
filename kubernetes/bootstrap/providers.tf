terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.35.1"
    }
    proxmox = {
      source = "bpg/proxmox"
      version = "0.69.1"
    }
  }
}
