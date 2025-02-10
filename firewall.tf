resource "hcloud_firewall" "node_firewall_ssh" {
  name = "limit-ssh"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = concat(data.tfe_outputs.hcloud_main.nonsensitive_values.rancher_nodes_ipv4, var.firewall_whitelist_ipv4)
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "2376"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Docker daemon TLS port used by Docker Machine"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "9345"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Node registration. Port should be open on all server nodes to all other nodes in the cluster"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Kubernetes API"
  }
  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "8285"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "flannel overlay network - udp backend. This is the default network configuration (only required if using flannel)"
  }
  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "8472"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "flannel overlay network - vxlan backend (only required if using flannel)"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "9099"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Canal/Flannel livenessProbe/readinessProbe"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "179"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Calico networking (BGP)"
  }
  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "4789"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Calico networking with VXLAN enabled"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10249"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "metrics"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10250"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "kubelet"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10256"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "kube-proxy"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10257"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "kube-controller-manager"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10259"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "	kube-scheduler"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "9100"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "http-metrics"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "4149"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "cadvisor"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10255"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "http-metrics"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10254"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Ingress controller livenessProbe/readinessProbe"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "2379"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "etcd client port"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "2380"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "etcd peer port"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "30000-32767"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "NodePort port range. Can use TCP or UDP"
  }
  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "30000-32767"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "NodePort port range. Can use TCP or UDP"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "5473"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Required when deploying with Calico"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Rancher UI/API when external SSL termination is used"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Rancher agent, Rancher UI/API, kubectl. Not needed if you have a load balancer doing TLS termination"
  }
}