resource "proxmox_virtual_environment_role" "ccm" {
  role_id    = "CCM"
  privileges = ["VM.Audit"]
}

resource "proxmox_virtual_environment_user" "kubernetes-ccm" {
  comment = "Managed by OpenTofu"
  user_id = "kubernetes-ccm@pve"
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.ccm.role_id
  }
}

resource "proxmox_virtual_environment_user_token" "kubernetes-ccm-token" {
  comment               = "Managed by OpenTofu"
  token_name            = "ccm"
  user_id               = proxmox_virtual_environment_user.kubernetes-ccm.user_id
  privileges_separation = false
}

resource "kubernetes_secret" "proxmox-ccm-config" {
  metadata {
    name      = "proxmox-ccm-config"
    namespace = "kube-system"
  }

  data = {
    "config.yaml" = <<EOF
clusters:
- url: "https://${var.proxmox_ip}:8006/api2/json"
  insecure: true
  token_id: "${proxmox_virtual_environment_user_token.kubernetes-ccm-token.id}"
  token_secret: "${element(split("=", proxmox_virtual_environment_user_token.kubernetes-ccm-token.value), length(split("=", proxmox_virtual_environment_user_token.kubernetes-ccm-token.value)) - 1)}"
  region: ${var.proxmox_cluster}
EOF
  }
}

resource "helm_release" "proxmox-ccm" {
  repository = "oci://ghcr.io/sergelogvinov/charts"
  chart      = "proxmox-cloud-controller-manager"
  version    = "0.2.13"

  name      = "proxmox-cloud-controller-manager"
  namespace = "kube-system"

  values = [file("kubernetes/manifests/infra/controllers/proxmox-ccm/values.yaml")]
}
