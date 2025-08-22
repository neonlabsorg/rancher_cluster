# cluster Etcd Backup
resource "rancher2_etcd_backup" "backup" {
  backup_config {
    enabled = true
    interval_hours = 24
    retention = 100
    s3_backup_config {
      access_key = var.etcd_backup_access_key
      bucket_name = var.etcd_backup_s3_bucket
      endpoint = var.etcd_backup_s3_endpoint
      folder = "/etcd-backup"
      region = var.etcd_backup_s3_region
      secret_key = var.etcd_backup_secret_key
    }
  }
  cluster_id = rancher2_cluster.hetzner.id
  name = "${var.cluster_name}-etcd-backup"
}