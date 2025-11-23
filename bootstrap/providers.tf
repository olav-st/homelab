terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.8.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
}
