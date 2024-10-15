terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 3.2.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    github = {
      source = "integrations/github"
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
  host             = local.raw_kubeconfig["clusters"][0]["cluster"]["server"]
  token            = local.raw_kubeconfig["users"][0]["user"]["token"]
  insecure         = true
  load_config_file = false
}

provider "github" {
  owner = var.github_repository_owner
  token = var.github_token
}