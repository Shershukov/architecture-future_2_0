output "network_id" {
  description = "ID VPC сети"
  value       = yandex_vpc_network.main.id
}

output "bastion_public_ip" {
  description = "Публичный IP бастиона"
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "k8s_cluster_id" {
  description = "ID Kubernetes кластера"
  value       = yandex_kubernetes_cluster.main.id
}

output "data_lake_bucket" {
  description = "Имя бакета Data Lake"
  value       = yandex_storage_bucket.data_lake.bucket
}

output "vault_cluster_id" {
  description = "ID PostgreSQL кластера Vault"
  value       = yandex_mdb_postgresql_cluster.vault.id
}

output "terraform_managed" {
  description = "Компоненты, управляемые Terraform"
  value = [
    "Network (VPC, Subnets)",
    "Security Groups, KMS",
    "Kubernetes Cluster + Nodes",
    "Bastion VM",
    "Object Storage (Data Lake)",
    "Managed PostgreSQL (Vault)"
  ]
}

output "manual_deployment_required" {
  description = "Компоненты для ручного развёртывания"
  value = [
    "SSL Certificates (Certificate Manager)",
    "Secrets (Lockbox)",
    "Compliance Approvals",
    "DNS Configuration"
  ]
}