terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.49.1"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 3.2.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.6.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.3.1"
    }
  }
}

provider "rancher2" {
  api_url   = var.admin_url
  token_key = var.admin_token
}

locals {
  raw_kubeconfig = nonsensitive(yamldecode(rancher2_cluster.hetzner.kube_config))
}

provider "flux" {
  kubernetes = {
    host     = local.raw_kubeconfig["clusters"][0]["cluster"]["server"]
    token    = local.raw_kubeconfig["users"][0]["user"]["token"]
    insecure = true
  }
  git = {
    url = "ssh://git@github.com/${var.github_repository_owner}/${var.github_repository_name}.git"
    ssh = {
      username    = "git"
      private_key = tls_private_key.git-main.private_key_pem
    }
  }
}

provider "kubectl" {
  host              = local.raw_kubeconfig["clusters"][0]["cluster"]["server"]
  token             = local.raw_kubeconfig["users"][0]["user"]["token"]
  insecure          = true
  load_config_file  = false
  apply_retry_count = 10
}

provider "github" {
  owner = var.github_repository_owner
  token = var.github_token
}

### Because we use custom nodeTemplates manifests, we have to put it directly to rancher mgmt cluster, so this provider connects to mgmt cluster

provider "kubectl" {
  alias = "rancher_mgmt_cluster"
  host  = data.tfe_outputs.hcloud_main.nonsensitive_values.rancher_mgmt_cluster_host

  client_certificate     = data.tfe_outputs.hcloud_main.nonsensitive_values.rancher_mgmt_cluster_client_cert
  client_key             = data.tfe_outputs.hcloud_main.nonsensitive_values.rancher_mgmt_cluster_client_key
  cluster_ca_certificate = data.tfe_outputs.hcloud_main.nonsensitive_values.rancher_mgmt_cluster_ca
  load_config_file       = false
  apply_retry_count      = 10
}
