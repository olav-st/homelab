locals {
  haos = {
    version    = "14.2" # renovate: github-releases=home-assistant/operating-system
    base_url   = "https://github.com/home-assistant/operating-system/releases/download"
    local_file = "home-assistant/haos_ova.qcow2"
  }
}

resource "null_resource" "haos_image" {
  triggers = {
    on_version_change = "${local.haos.version}"
    filename = local.haos.local_file
  }

  provisioner "local-exec" {
    command = "curl -s -L ${local.haos.base_url}/${local.haos.version}/haos_ova-${local.haos.version}.qcow2.xz | xz -d > ${self.triggers.filename}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm ${self.triggers.filename}"
  }
}

resource "proxmox_virtual_environment_file" "haos_generic_image_nuc" {
  depends_on = [ null_resource.haos_image ]
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_file {
    path      = local.haos.local_file
    file_name = "haos_ova-${local.haos.version}.img"
  }
}
