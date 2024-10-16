locals {
  required_node_templates = merge([{ for node_pool in var.cluster_configurations.node_pools : "${node_pool.server_type}--${node_pool.server_location}--${node_pool.image}--${node_pool.name}" => node_pool }]...)
  required_node_pools     = merge([{ for node_pool in var.cluster_configurations.node_pools : "${var.cluster_name}--${node_pool.name}" => node_pool }]...)
}

resource "rancher2_node_template" "hetzner" {
  for_each  = local.required_node_templates
  name      = each.key
  driver_id = "hetzner"
  hetzner_config {
    api_token           = var.hetzner_token
    image               = each.value.image
    server_location     = each.value.server_location
    server_type         = each.value.server_type
    networks            = var.management_network_id
    use_private_network = each.value.use_private_network
  }
  labels = {
    "cluster-name" = var.cluster_name
  }
  lifecycle {
    ignore_changes = [name] # Fix to don't destroy test cluster
  }
}

resource "rancher2_node_pool" "hetzner" {
  for_each         = local.required_node_pools
  cluster_id       = rancher2_cluster.hetzner.id
  name             = each.key
  hostname_prefix  = each.key
  node_template_id = rancher2_node_template.hetzner["${each.value.server_type}--${each.value.server_location}--${each.value.image}--${each.value.name}"].id
  quantity         = each.value.quantity
  control_plane    = each.value.control_plane
  etcd             = each.value.etcd
  worker           = each.value.worker
  labels           = each.value.labels
  dynamic "node_taints" {
    for_each = each.value.node_taints != null ? each.value.node_taints : []
    content {
      key    = node_taints.value.key
      value  = node_taints.value.value
      effect = node_taints.value.effect
    }
  }
  lifecycle {
    ignore_changes = [name] # Fix to don't destroy test cluster
  }
}

resource "rancher2_cluster" "hetzner" {
  name        = var.cluster_name
  description = var.cluster_configurations.description
  rke_config {
    addons         = <<EOF
---
apiVersion: v1
stringData:
  token: ${var.hetzner_token}
  network: ${var.management_network_name}
kind: Secret
metadata:
  name: hcloud
  namespace: kube-system
    EOF
    addons_include = ["https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm-networks.yaml"]
    services {
      kubelet {
        extra_args = {
          "cloud-provider" = "external"
        }
      }
    }
    kubernetes_version = var.cluster_configurations.kubernetes_version
    enable_cri_dockerd = true
    network {
      plugin = "canal"
    }
    ingress {
      provider = "none"
    }
  }
}

resource "rancher2_cluster_sync" "hetzner" {
  cluster_id    = rancher2_cluster.hetzner.id
  node_pool_ids = [for node_pool in rancher2_node_pool.hetzner : node_pool.id]
}
