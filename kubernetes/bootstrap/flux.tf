# Add deploy key to GitHub repository
resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "Flux"
  repository = var.github_repository
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "true"
}

# Install Flux
resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }
}

resource "helm_release" "flux2" {
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = "2.14.1"

  name      = "flux2"
  namespace = "flux-system"

  depends_on = [kubernetes_namespace.flux_system]
}

# Bootstrap Flux
resource "kubernetes_secret" "ssh_keypair" {
  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }

  type = "Opaque"

  data = {
    "identity.pub" = tls_private_key.flux.public_key_openssh
    "identity"     = tls_private_key.flux.private_key_pem
    "known_hosts"  = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
  }

  depends_on = [kubernetes_namespace.flux_system]
}

resource "helm_release" "flux2_sync" {
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2-sync"
  version    = "1.10.0"

  name      = "flux-system"
  namespace = "flux-system"

  values   = [yamlencode({
    gitRepository = {
      spec = {
        url = "ssh://git@github.com/${var.github_org}/${var.github_repository}.git"
        interval = "3m"
        ref = {
          branch = "rendered_manifests"
        }
        secretRef = {
          name = kubernetes_secret.ssh_keypair.metadata[0].name
        }
      }
    }
    kustomization = false
    kustomizationlist = [
      {
        spec = {
          path = "./crds"
          interval = "15m"
          timeout = "10m"
          prune = true
        }
      },
      {
        spec = {
          dependsOn = [
            {
              path = "./crds"
            }
          ]
          path = "./resources"
          interval = "15m"
          timeout = "10m"
          prune = true
        }
      },
      {
        spec = {
          dependsOn = [
            {
              path = "./resources"
            }
          ]
          path = "./composite-resources"
          interval = "15m"
          timeout = "10m"
          prune = true
        }
      }
    ]
  })]

  depends_on = [helm_release.flux2]
}
