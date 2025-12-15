terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
}
