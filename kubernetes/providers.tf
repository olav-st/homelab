terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.74.1"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.7.1"
    }
  }
}
