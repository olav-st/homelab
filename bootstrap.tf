module "bootstrap" {
  source     = "./bootstrap"

  github_org        = var.github_org
  github_repository = var.github_repository
  github_branch     = var.github_branch

  sealed_secrets_cert = var.sealed_secrets_cert
  sealed_secrets_key  = var.sealed_secrets_key
}
