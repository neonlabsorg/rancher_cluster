resource "hcloud_firewall" "node_firewall_ssh" {
  name = "limit-ssh"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = concat(data.tfe_outputs.hcloud_main.nonsensitive_values.rancher_nodes_ipv4, var.firewall_whitelist_ipv4)
  }
}