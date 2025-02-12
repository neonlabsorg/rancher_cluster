data "tfe_outputs" "hcloud_main" {
  organization = "neonlabs"
  workspace    = "hcloud"
}

data "rancher2_user" "default_admin" {
  username = "admin"
}