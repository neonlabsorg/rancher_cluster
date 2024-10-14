# Required
variable "cluster_name" {
  type        = string
  description = "Rancher Cluster Name"
}

# Required
variable "hetzner_token" {
  type        = string
  description = "Hetzner Cloud API Token"
}

# Required
variable "cluster_configurations" {
  description = "value for the cluster configurations"
  type = object({
    description        = string
    kubernetes_version = string
    node_pools = list(object({
      name            = string
      use_private_network = optional(bool, true)
      server_type     = string
      server_location = string
      image           = string
      quantity        = number
      control_plane   = bool
      etcd            = bool
      worker          = bool
      node_taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })))
    }))
  })
}

# Required
variable "management_network_id" {
  type        = string
  description = "Rancher Management Network ID"
}

# Required
variable "management_network_name" {
  type        = string
  description = "Rancher Management Network Name"
}

# Required
variable "admin_url" {
  type        = string
  description = "Rancher Admin URL"
}

# Required
variable "admin_token" {
  type        = string
  description = "Rancher Admin Token"
}

# Required
variable "github_token" {
  type        = string
  description = "Flux repository github token"
  sensitive   = true
}

variable "github_repository_owner" {
  type        = string
  default     = "neonlabsorg"
  description = "Flux repository github owner"
}

variable "github_repository_name" {
  type        = string
  default     = "flux-infra"
  description = "Flux repository name"
}

variable "github_repository_branch" {
  type        = string
  default     = "main"
  description = "Default branch to sync from"
}

variable "flux_namespace" {
  type        = string
  default     = "flux-system"
  description = "The namespace scope for this operation"
}

variable "flux_repo_target_path" {
  type        = string
  default     = null
  description = "Relative path to the Git repository root where Flux manifests are committed"
}

variable "flux_components" {
  type        = list(string)
  default     = ["source-controller", "kustomize-controller", "helm-controller", "notification-controller"]
  description = "Toolkit components to include in the install manifests"
}

variable "flux_components_extra" {
  type        = list(string)
  default     = ["image-reflector-controller", "image-automation-controller"]
  description = "List of extra components to include in the install manifests"
}

variable "flux_version" {
  type        = string
  default     = "latest"
  description = "Flux version"
}

variable "flux_registry" {
  type        = string
  default     = "ghcr.io/fluxcd"
  description = "Container registry where the toolkit images are published"
}

variable "flux_image_pull_secret" {
  type        = string
  default     = null
  description = "Kubernetes secret name used for pulling the toolkit images from a private registry"
}
