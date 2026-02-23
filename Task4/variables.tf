variable "yc_cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "yc_folder_id" {
  description = "ID каталога"
  type        = string
}

variable "yc_default_zone" {
  description = "Зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-a"
}

variable "subnet_zones" {
  description = "Зоны для создания подсетей"
  type        = set(string)
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
}

variable "public_cidrs" {
  description = "CIDR для публичных подсетей по зонам"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.0.1.0/24"
    "ru-central1-b" = "10.0.2.0/24"
    "ru-central1-d" = "10.0.3.0/24"
  }
}

variable "private_cidrs" {
  description = "CIDR для приватных подсетей по зонам"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.0.11.0/24"
    "ru-central1-b" = "10.0.12.0/24"
    "ru-central1-d" = "10.0.13.0/24"
  }
}

variable "yc_oauth_token" {
  description = "IAM-токен для аутентификации (только для тестов!)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "project_name" {
  description = "Имя проекта"
  type        = string
  default     = "terraform-backend"
}

variable "environment" {
  description = "Окружение: dev/staging/prod"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Ответственная команда"
  type        = string
  default     = "platform-team"
}

variable "public_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_cidr" {
  type    = string
  default = "10.0.11.0/24"
}

variable "k8s_version" {
  description = "Версия Kubernetes"
  type        = string
  default     = "1.27"
}

variable "k8s_node_count" {
  description = "Количество нод в кластере"
  type        = number
  default     = 3
}

variable "bastion_ssh_public_key" {
  description = "Публичный SSH-ключ для бастиона"
  type        = string
  default     = ""
}

variable "postgres_version" {
  description = "Версия PostgreSQL"
  type        = string
  default     = "15"
}

variable "vault_preset" {
  description = "Пресет ресурсов для Vault"
  type        = string
  default     = "s2.medium"
}

variable "vault_disk_size" {
  description = "Размер диска Vault (GB)"
  type        = number
  default     = 50
}

variable "vault_db_username" {
  description = "Пользователь БД Vault"
  type        = string
  default     = "vault_admin"
}

variable "vault_db_password" {
  description = "Пароль БД Vault (в prod использовать Lockbox!)"
  type        = string
  sensitive   = true
}

variable "data_lake_max_size" {
  description = "Макс. размер Data Lake (GB)"
  type        = number
  default     = 5
}

variable "backup_retention_days" {
  description = "Срок хранения бэкапов (дни)"
  type        = number
  default     = 30
}