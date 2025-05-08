resource "proxmox_virtual_environment_vm" "home_assistant" {
  name        = "Home-Assistant"
  description = "Managed by OpenTofu"
  tags        = ["tofu"]
  on_boot     = true
  bios        = "ovmf"

  node_name   = var.proxmox_node
  vm_id       = var.proxmox_vm_id

  cpu {
    cores = 1
  }

  memory {
    dedicated = 2048
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    mac_address = "EE:88:64:5F:EA:95"
  }

  efi_disk {
    datastore_id = "local-zfs"
    file_format  = "raw"
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_file.haos_generic_image.id
    interface    = "virtio0"
    size         = 64
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  usb {
    host = "10c4:ea60" # Nabu Casa SkyConnect
  }

  usb {
    host = "0a12:0001" # CSR8510 Bluetooth Adapter
  }

  lifecycle {
    prevent_destroy = true
  }
}
