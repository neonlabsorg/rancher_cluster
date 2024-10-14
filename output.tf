output "rancher_cluster" {
  value = nonsensitive(rancher2_cluster.hetzner.*.kube_config)
}
output "ipv4_addresses" {
  value = rancher2_cluster_sync.hetzner.nodes[*].external_ip_address
}
