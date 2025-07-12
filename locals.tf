locals {
  nodes = {
    "talos-cp-01" = {
      type         = "controlplane"
      cpus         = 4
      memory       = 12288
      bootstrap    = true
      ip_address   = "192.168.0.190"
      install_disk = "/dev/nvme0n1"
    }
  }
  bootstrap_node = one([for name, node in local.nodes : name if node.bootstrap == true])
}
