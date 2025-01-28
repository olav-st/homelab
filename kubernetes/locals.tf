locals {
  talos = {
    current_version = "v1.9.2"
    upgrade_version = "v1.9.2" # renovate: github-releases=siderolabs/talos
    base_url        = "https://factory.talos.dev/image/787b79bb847a07ebb9ae37396d015617266b1cef861107eaec85968ad7b40618"
  }

  is_upgrade = local.talos.upgrade_version != local.talos.current_version

  nodes = merge(
    {
      for i in range(var.controlplane_count) :
      "talos-cp-${substr(sha256("${i}${local.talos.current_version}"), 0, 7)}" => {
        type      = "controlplane"
        cpus      = 4
        memory    = 14336
        image     = proxmox_virtual_environment_download_file.talos_image[local.talos.current_version].id
        bootstrap = (i == 0)
      }
    },
    {
      for i in(local.is_upgrade ? range(var.controlplane_count) : []) :
      "talos-cp-${substr(sha256("${i}${local.talos.upgrade_version}"), 0, 7)}" => {
        type      = "controlplane"
        cpus      = 4
        memory    = 14336
        image     = proxmox_virtual_environment_download_file.talos_image[local.talos.upgrade_version].id
        bootstrap = false
      }
    },
    {
      for i in range(var.worker_count) :
      "talos-worker-${substr(sha256("${i}${local.talos.current_version}"), 0, 7)}" => {
        type      = "worker"
        cpus      = 4
        memory    = 4096
        image     = proxmox_virtual_environment_download_file.talos_image[local.talos.current_version].id
        bootstrap = false
      }
    },
    {
      for i in(local.is_upgrade ? range(var.worker_count) : []) :
      "talos-worker-${substr(sha256("${i}${local.talos.upgrade_version}"), 0, 7)}" => {
        type      = "worker"
        cpus      = 4
        memory    = 4096
        image     = proxmox_virtual_environment_download_file.talos_image[local.talos.upgrade_version].id
        bootstrap = false
      }
    },
  )

  node_ips = {
    for vm in proxmox_virtual_environment_vm.talos :
    vm.name => [for ip in flatten(vm.ipv4_addresses) : ip if cidrhost("${ip}/${var.subnet_mask}", 1) == var.default_gateway && ip != var.cluster_vip]
  }

  bootstrap_node = one([for key, value in local.nodes : key if value.bootstrap == true])

  images = merge(
    {
      "${local.talos.current_version}" = {
        file_name               = "talos-${local.talos.current_version}-nocloud-amd64.img"
        url                     = "${local.talos.base_url}/${local.talos.current_version}/nocloud-amd64.raw.gz"
        decompression_algorithm = "gz"
      }
    },
    local.is_upgrade ? {
      "${local.talos.upgrade_version}" = {
        file_name               = "talos-${local.talos.upgrade_version}-nocloud-amd64.img"
        url                     = "${local.talos.base_url}/${local.talos.upgrade_version}/nocloud-amd64.raw.gz"
        decompression_algorithm = "gz"
      }
    }
    :
    {}
  )
}
