terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.120.0"
    }
  }

  backend "s3" {
    endpoints = { s3 = "https://storage.yandexcloud.net" }
    bucket     = "budushchee-tf-state"
    key        = "prod/terraform.tfstate"
    region     = "ru-central1"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    use_lockfile                = true
  }
}

provider "yandex" {
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_default_zone
  token = var.yc_oauth_token
}

resource "yandex_vpc_network" "main" {
  name = "${var.project_name}-${var.environment}-network"
}

resource "yandex_vpc_subnet" "public" {
  for_each = var.subnet_zones

  name           = "${var.project_name}-public-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_cidrs[each.key]]
}

resource "yandex_vpc_subnet" "private" {
  for_each = var.subnet_zones

  name           = "${var.project_name}-private-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_cidrs[each.key]]
}

resource "yandex_vpc_security_group" "main" {
  name        = "${var.project_name}-main-sg"
  network_id  = yandex_vpc_network.main.id
  description = "Main security group"

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "HTTPS from anywhere"
  }

  ingress {
    protocol       = "ANY"
    v4_cidr_blocks = values(var.private_cidrs)
    description    = "Internal traffic from private subnets"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound"
  }
}

resource "yandex_kms_symmetric_key" "main" {
  name              = "${var.project_name}-key"
  default_algorithm = "AES_256"
  rotation_period   = "7776000s"
}

resource "yandex_iam_service_account" "k8s" {
  name = "${var.project_name}-k8s-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:aje36ogaht49oljr1i02"
}

resource "yandex_kubernetes_cluster" "main" {
  name        = "${var.project_name}-k8s"
  network_id  = yandex_vpc_network.main.id

  master {
    regional {
      region = "ru-central1"

      location {
        zone      = "ru-central1-a"
        subnet_id = yandex_vpc_subnet.private["ru-central1-a"].id
      }
      location {
        zone      = "ru-central1-b"
        subnet_id = yandex_vpc_subnet.private["ru-central1-b"].id
      }
      location {
        zone      = "ru-central1-d"
        subnet_id = yandex_vpc_subnet.private["ru-central1-d"].id
      }
    }
    version   = var.k8s_version
    public_ip = true
  }
  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id
  release_channel = "STABLE"
}

resource "yandex_kubernetes_node_group" "main" {
  cluster_id = yandex_kubernetes_cluster.main.id
  name       = "${var.project_name}-nodes"
  version    = var.k8s_version

  instance_template {
    platform_id = "standard-v3"

    resources {
      memory        = 4
      cores         = 2
      core_fraction = 20
    }

    boot_disk {
      type = "network-ssd"
      size = 50
    }

    network_interface {
      subnet_ids         = [for s in yandex_vpc_subnet.private : s.id]
      nat                = false
      security_group_ids = [yandex_vpc_security_group.main.id]
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale { size = var.k8s_node_count }
  }

  allocation_policy {
    location { zone = var.yc_default_zone }
  }

  depends_on = [yandex_kubernetes_cluster.main]
}

resource "yandex_compute_instance" "bastion" {
  name = "${var.project_name}-bastion"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      type     = "network-ssd"
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public[var.yc_default_zone].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.main.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.bastion_ssh_public_key}"
  }
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_storage_bucket" "data_lake" {
  bucket   = "${var.project_name}-data-lake-${var.environment}"
  max_size = var.data_lake_max_size
  access_key =""
  secret_key =""

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = yandex_kms_symmetric_key.main.id
      }
    }
  }

  lifecycle {
    ignore_changes = [
      bucket,
      max_size,
    ]
  }
}

resource "yandex_mdb_postgresql_cluster" "vault" {
  name        = "${var.project_name}-vault"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id

  config {
    version = var.postgres_version
    resources {
      resource_preset_id = var.vault_preset
      disk_size          = 10
      disk_type_id       = "network-ssd"
    }
  }

  host {
    zone      = var.yc_default_zone
    subnet_id = yandex_vpc_subnet.private[var.yc_default_zone].id
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Compliance  = "152-FZ"
  }
}