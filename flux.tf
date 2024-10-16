resource "tls_private_key" "git-main" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "main" {
  title      = "hcloud-${var.cluster_name}"
  repository = var.github_repository_name
  key        = tls_private_key.git-main.public_key_openssh
  read_only  = false
}

resource "flux_bootstrap_git" "main" {
  embedded_manifests = true
  network_policy     = true
  components         = var.flux_components
  components_extra   = var.flux_components_extra
  namespace          = var.flux_namespace
  registry           = var.flux_registry
  version            = var.flux_version
  image_pull_secret  = var.flux_image_pull_secret
  path               = try(length(var.flux_repo_target_path), 0) > 0 ? var.flux_repo_target_path : "clusters/hcloud-${var.cluster_name}"

  depends_on = [github_repository_deploy_key.main, rancher2_cluster.hetzner, kubectl_manifest.flux_namespace]
}
