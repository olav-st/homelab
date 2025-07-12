variable "github_org" {
  type    = string
  default = "olav-st"
}

variable "github_repository" {
  type    = string
  default = "homelab"
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "cluster_name" {
  type    = string
  default = "homelab"
}

variable "default_gateway" {
  type    = string
  default = "192.168.0.1"
}

variable "cluster_vip" {
  type    = string
  default = "192.168.0.90"
}

variable "sealed_secrets_cert" {
  type      = string
  sensitive = true
}

variable "sealed_secrets_key" {
  type      = string
  sensitive = true
}

variable "letsencrypt_contact_email" {
  type = string
}

variable "cloudflare_dns_email" {
  type = string
}

variable "cloudflare_dns_token" {
  type      = string
  sensitive = true
}
