yc_default_zone = "ru-central1-a"
subnet_zones = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]

project_name = "budushchee-2-0"
environment  = "prod"
owner        = "platform-team@budushchee.ru"

public_cidr  = "10.0.1.0/24"
private_cidr = "10.0.11.0/24"

public_cidrs = {
  "ru-central1-a" = "10.0.1.0/24"
  "ru-central1-b" = "10.0.2.0/24"
  "ru-central1-d" = "10.0.3.0/24"
}

private_cidrs = {
  "ru-central1-a" = "10.0.11.0/24"
  "ru-central1-b" = "10.0.12.0/24"
  "ru-central1-d" = "10.0.13.0/24"
}

k8s_version            = "1.33"
k8s_node_count         = 3
bastion_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... user@host"

postgres_version    = "15"
vault_preset        = "s2.medium"
vault_disk_size     = 10
vault_db_username   = "vault_admin"
vault_db_password   = "TempPassword123!"

data_lake_max_size    = 0
backup_retention_days = 30