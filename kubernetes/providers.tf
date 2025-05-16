terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.78.0"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.8.0"
    }
  }
}
