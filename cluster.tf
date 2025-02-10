locals {
  required_node_templates   = merge([{ for node_pool in var.cluster_configurations.node_pools : "${node_pool.server_type}--${node_pool.server_location}--${node_pool.image}--${node_pool.name}" => node_pool if !node_pool.autoscaling }]...)
  required_node_pools       = merge([{ for node_pool in var.cluster_configurations.node_pools : "${var.cluster_name}--${node_pool.name}" => node_pool if !node_pool.autoscaling }]...)
  autoscaled_node_templates = merge([{ for node_pool in var.cluster_configurations.node_pools : "${node_pool.server_type}--${node_pool.server_location}--${node_pool.image}--${node_pool.name}" => node_pool if node_pool.autoscaling }]...)
  autoscaled_node_pools     = merge([{ for node_pool in var.cluster_configurations.node_pools : "${var.cluster_name}--${node_pool.name}" => node_pool if node_pool.autoscaling }]...)
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
    userdata            = file("${path.module}/cloud-init/init.yaml")
  }
  labels = merge({
    "cluster-name" = var.cluster_name
  }, each.value.labels)
}

# resource "rancher2_node_template" "hetzner-autoscaled" {
#   for_each  = local.autoscaled_node_templates
#   name      = each.key
#   driver_id = "hetzner"
#   hetzner_config {
#     api_token           = var.hetzner_token
#     image               = each.value.image
#     server_location     = each.value.server_location
#     server_type         = each.value.server_type
#     networks            = var.management_network_id
#     use_private_network = each.value.use_private_network
#     userdata            = file("${path.module}/cloud-init/init.yaml")
#   }
#   labels = merge({
#     "cluster-name" = var.cluster_name
#   }, each.value.labels)
# }

resource "rancher2_node_pool" "hetzner" {
  for_each         = local.required_node_pools
  cluster_id       = rancher2_cluster.hetzner.id
  name             = each.key
  hostname_prefix  = each.key
  node_template_id = rancher2_node_template.hetzner["${each.value.server_type}--${each.value.server_location}--${each.value.image}--${each.value.name}"].id
  #  node_template_id = "cattle-global-nt:nt-${random_string._autoscaled_template_name_hash["${each.value.server_type}--${each.value.server_location}--${each.value.image}--${each.value.name}"].result}"
  quantity      = each.value.quantity
  control_plane = each.value.control_plane
  etcd          = each.value.etcd
  worker        = each.value.worker

  dynamic "node_taints" {
    for_each = each.value.node_taints != null ? each.value.node_taints : []
    content {
      key    = node_taints.value.key
      value  = node_taints.value.value
      effect = node_taints.value.effect
    }
  }
  # depends_on = [kubectl_manifest.node_template]
}

resource "rancher2_node_pool" "hetzner-autoscaled" {
  for_each        = local.autoscaled_node_pools
  cluster_id      = rancher2_cluster.hetzner.id
  name            = each.key
  hostname_prefix = each.key
  #  node_template_id = rancher2_node_template.hetzner-autoscaled["${each.value.server_type}--${each.value.server_location}--${each.value.image}--${each.value.name}"].id
  node_template_id = "cattle-global-nt:nt-${random_string._autoscaled_template_name_hash["${each.value.server_type}--${each.value.server_location}--${each.value.image}--${each.value.name}"].result}"
  quantity         = each.value.quantity
  control_plane    = each.value.control_plane
  etcd             = each.value.etcd
  worker           = each.value.worker

  dynamic "node_taints" {
    for_each = each.value.node_taints != null ? each.value.node_taints : []
    content {
      key    = node_taints.value.key
      value  = node_taints.value.value
      effect = node_taints.value.effect
    }
  }
  lifecycle {
    ignore_changes = [quantity] # Fix to don't destroy test cluster
  }

  depends_on = [kubectl_manifest.autoscaled_node_template]
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
  lifecycle {
    ignore_changes = [annotations] # Fix to don't destroy test cluster
  }
}

resource "rancher2_cluster_sync" "hetzner" {
  cluster_id    = rancher2_cluster.hetzner.id
  node_pool_ids = concat([for node_pool in rancher2_node_pool.hetzner : node_pool.id], [for node_pool in rancher2_node_pool.hetzner-autoscaled : node_pool.id])
}

resource "random_string" "_template_name_hash" {
  for_each = local.required_node_templates
  length   = 5
  special  = false
  upper    = false
}

resource "random_string" "_autoscaled_template_name_hash" {
  for_each = local.autoscaled_node_templates
  length   = 5
  special  = false
  upper    = false
}

# resource "kubectl_manifest" "node_template" {
#   provider = kubectl.rancher_mgmt_cluster
#   for_each  = local.required_node_templates
#   yaml_body = templatefile("${path.module}/templates/node-template.yaml.tftpl", {
#     default_admin_id    = data.rancher2_user.default_admin.id
#     hcloud_token        = var.hetzner_token
#     name                = each.key
#     name_hash           = random_string._template_name_hash[each.key].result
#     firewall_id         = hcloud_firewall.node_firewall_ssh.id
#     cluster_name        = var.cluster_name
#     image               = each.value.image
#     server_location     = each.value.server_location
#     server_type         = each.value.server_type
#     use_private_network = each.value.use_private_network
#     userdata            = indent(4, file("${path.module}/cloud-init/init.yaml"))
#   })
# }

resource "kubectl_manifest" "autoscaled_node_template" {
  provider = kubectl.rancher_mgmt_cluster
  # Ref: https://github.com/rancher/rancher/blob/c00c7e0f1a3a5f956ae600b2d0d293357f161284/pkg/apis/management.cattle.io/v3/machine_types.go#L50-L54
  # Ref: https://github.com/JonasProgrammer/docker-machine-driver-hetzner/blob/d97bd3baac3a3d09b0384829b7a05f00e0e7784d/driver/driver.go#L69-L115
  for_each = local.autoscaled_node_templates
  yaml_body = nonsensitive(templatefile("${path.module}/templates/node-template.yaml.tftpl", {
    default_admin_id    = data.rancher2_user.default_admin.id
    hcloud_token        = var.hetzner_token
    name                = each.key
    name_hash           = random_string._autoscaled_template_name_hash[each.key].result
    firewall_id         = hcloud_firewall.node_firewall_ssh.id
    cluster_name        = var.cluster_name
    image               = each.value.image
    server_location     = each.value.server_location
    server_type         = each.value.server_type
    use_private_network = each.value.use_private_network
    userdata            = indent(4, file("${path.module}/cloud-init/init.yaml"))
  }))
}
