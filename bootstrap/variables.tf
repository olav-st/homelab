variable "github_org" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "sealed_secrets_cert" {
  type      = string
  sensitive = true
}

variable "sealed_secrets_key" {
  type      = string
  sensitive = true
}
