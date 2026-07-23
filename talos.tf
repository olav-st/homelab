resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = flatten([for name, node in local.nodes : node.ip_address if node.type == "controlplane"])
}

data "talos_machine_configuration" "this" {
  for_each = local.nodes

  talos_version      = "v1.13.3" # renovate: github-releases=siderolabs/talos
  kubernetes_version = "v1.36.3" # renovate: github-releases=kubernetes/kubernetes

  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cluster_vip}:6443"
  machine_type     = each.value.type
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = [
    templatefile("talos/machineconfig.yaml.tftpl", {
      hostname        = each.key
      machine_type    = each.value.type
      cluster_vip     = var.cluster_vip
      install_disk    = each.value.install_disk
      inline_manifests = [
        {
          name     = "cilium-install"
          contents = templatefile("talos/cilium-install.yaml.tftpl", {})
        }
      ]
    }),
    file("talos/uservolumeconfig.yaml"),
    file("talos/pcidriverrebindconfig.yaml"),
  ]
}

resource "talos_machine" "this" {
  for_each = local.nodes

  node                  = each.value.ip_address
  client_configuration  = data.talos_client_configuration.this.client_configuration
  machine_configuration = data.talos_machine_configuration.this[each.key].machine_configuration

  # nocloud image with siderolabs/intel-ucode, siderolabs/i915, siderolabs/amdgpu, siderolabs/iscsi-tools and siderolabs/util-linux-tools extensions
  image                 = "factory.talos.dev/metal-installer/5fad2b86ebfc72aaaf4ebc31cc5c36642af6f8557f35132be6d86196058790a6:v1.13.3" # renovate: github-releases=siderolabs/talos
}

resource "talos_machine_configuration_apply" "this" {
  for_each = local.nodes

  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  node                        = each.value.ip_address

  on_destroy = {
    graceful = true
    reboot   = false
    reset    = true
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]

  client_configuration = data.talos_client_configuration.this.client_configuration
  node                 = local.nodes[local.bootstrap_node].ip_address
}

resource "talos_cluster" "this" {
  depends_on           = [talos_machine_configuration_apply.this]
  node                 = local.nodes[local.bootstrap_node].ip_address
  client_configuration = talos_machine_secrets.this.client_configuration
  kubernetes_version   = "v1.36.3" # renovate: github-releases=kubernetes/kubernetes
}

data "talos_cluster_health" "this" {
  depends_on = [talos_machine_configuration_apply.this]

  client_configuration = data.talos_client_configuration.this.client_configuration
  control_plane_nodes  = flatten([for name, node in local.nodes : node.ip_address if node.type == "controlplane"])
  worker_nodes         = flatten([for name, node in local.nodes : node.ip_address if node.type == "worker"])
  endpoints            = data.talos_client_configuration.this.endpoints
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]

  client_configuration = data.talos_client_configuration.this.client_configuration
  node                 = var.cluster_vip
}
