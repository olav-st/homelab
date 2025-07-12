resource "kubernetes_namespace" "sealed-secrets" {
  metadata {
    name = "sealed-secrets"
  }
}

resource "kubernetes_secret" "sealed-secrets-key" {
  depends_on = [ kubernetes_namespace.sealed-secrets ]

  metadata {
    name = "sealed-secrets-key4x8nz"
    namespace = "sealed-secrets"
    labels = {
      "sealedsecrets.bitnami.com/sealed-secrets-key" = "active"
    }
  }

  data = {
    "tls.crt" = base64decode(var.sealed_secrets_cert)
    "tls.key" = base64decode(var.sealed_secrets_key)
  }

  type = "kubernetes.io/tls"
}
