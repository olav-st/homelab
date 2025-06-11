locals {
  connection = {
    host        = var.proxmox_ip
    user        = var.proxmox_user
    private_key = var.ssh_private_key
  }
  volumes = [
    {
      name = "gitea"
      size = 10
    },
    {
      name = "gitea-postgresql"
      size = 10
    },
    {
      name = "immich-library"
      size = 150
    },
    {
      name = "immich-postgresql"
      size = 10
    },
    {
      name = "netbird-management"
      size = 1
    },
    {
      name = "netbird-signal"
      size = 1
    },
    {
      name = "nextcloud-data"
      size = 300
    },
    {
      name = "nextcloud-mariadb"
      size = 10
    },
    {
      name = "ollama"
      size = 60
    },
    {
      name = "open-webui"
      size = 10
    },
    {
      name = "pingvinshare"
      size = 50
    },
    {
      name = "pingvinshare-postgresql"
      size = 10
    },
  ]
}

module "proxmox-volume" {
  for_each   = { for idx, volume in local.volumes : volume.name => volume }

  source     = "./proxmox-volume"
  connection = local.connection
  vm_id      = 9999
  name       = "vm-9999-pv-${each.value.name}"
  size       = each.value.size
  storage    = var.proxmox_storage
}

module "k8s-persistent-volume" {
  for_each        = { for idx, volume in local.volumes : volume.name => volume }
  depends_on      = [ module.proxmox-volume ]

  source          = "./k8s-persistent-volume"
  name            = each.value.name
  size            = each.value.size
  proxmox_cluster = var.proxmox_cluster
  proxmox_node    = var.proxmox_node
}
