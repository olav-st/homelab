resource "proxmox_virtual_environment_vm" "talos" {
  for_each = local.nodes

  name        = each.key
  description = "Managed by OpenTofu"
  tags        = ["tofu"]
  on_boot     = true
  machine     = "q35"

  node_name   = var.proxmox_node

  cpu {
    cores        = each.value.cpus
    type         = "x86-64-v3"
  }

  memory {
    dedicated = each.value.memory
  }

  agent {
    enabled = true
  }

  network_device {
    bridge      = "vmbr0"
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = each.value.image
    file_format  = "raw"
    interface    = "virtio0"
    size         = 512
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-zfs"
  }

  dynamic "hostpci" {
    for_each = each.value.pci_passthrough
    content {
      device = "hostpci${hostpci.key}"
      id     = hostpci.value
      pcie   = true
      rombar = true
    }
  }
}
