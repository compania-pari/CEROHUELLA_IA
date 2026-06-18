variable "environment" {
  description = "Environment name."
  type        = string
  default     = "qa"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Environment resource group name."
  type        = string
  default     = "rg-cerohuella-qa"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "lpari"
}

variable "cost_center" {
  description = "Cost center tag value."
  type        = string
  default     = "dmc"
}

variable "extra_tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}

variable "acr_id" {
  description = "Shared ACR resource ID."
  type        = string
}

variable "acr_login_server" {
  description = "Shared ACR login server."
  type        = string
}

variable "image_repository" {
  description = "Container image repository name."
  type        = string
  default     = "cerohuella-ia"
}

variable "image_tag" {
  description = "Container image tag."
  type        = string
  default     = "latest"
}

variable "virtual_network_name" {
  description = "Virtual network name."
  type        = string
  default     = "vnet-cerohuella-qa"
}

variable "address_space" {
  description = "Virtual network address space."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "container_apps_subnet_name" {
  description = "Container Apps subnet name."
  type        = string
  default     = "snet-containerapps-qa"
}

variable "container_apps_subnet_prefixes" {
  description = "Container Apps subnet prefixes."
  type        = list(string)
  default     = ["10.20.0.0/23"]
}

variable "postgresql_subnet_name" {
  description = "PostgreSQL delegated subnet name."
  type        = string
  default     = "snet-postgresql-qa"
}

variable "postgresql_subnet_prefixes" {
  description = "PostgreSQL subnet prefixes."
  type        = list(string)
  default     = ["10.20.2.0/24"]
}

variable "log_analytics_name" {
  description = "Log Analytics workspace name."
  type        = string
  default     = "law-cerohuella-qa"
}

variable "log_retention_days" {
  description = "Log retention in days."
  type        = number
  default     = 30
}

variable "application_insights_name" {
  description = "Application Insights name."
  type        = string
  default     = "appi-cerohuella-qa"
}

variable "container_apps_environment_name" {
  description = "Container Apps Environment name."
  type        = string
  default     = "cae-cerohuella-qa"
}

variable "managed_identity_name" {
  description = "Managed identity name."
  type        = string
  default     = "id-cerohuella-api-qa"
}

variable "container_app_name" {
  description = "Container App name."
  type        = string
  default     = "ca-cerohuella-api-qa"
}

variable "container_cpu" {
  description = "Container CPU."
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Container memory."
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum replicas."
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum replicas."
  type        = number
  default     = 1
}

variable "app_name" {
  description = "Application display name."
  type        = string
  default     = "CeroHuella IA API"
}

variable "app_port" {
  description = "Application port."
  type        = number
  default     = 8000
}

variable "storage_root" {
  description = "Local storage root inside the container."
  type        = string
  default     = "storage"
}

variable "max_file_size_mb" {
  description = "Maximum PDF size in MB."
  type        = number
  default     = 25
}

variable "max_batch_files" {
  description = "Maximum files per batch."
  type        = number
  default     = 10
}

variable "google_cloud_project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "google_application_credentials_b64" {
  description = "Google service account JSON encoded as Base64."
  type        = string
  sensitive   = true
}

variable "google_application_credentials_path" {
  description = "Path where the Google credentials file is written."
  type        = string
  default     = "/tmp/google-application-credentials.json"
}

variable "postgresql_server_name" {
  description = "PostgreSQL Flexible Server name."
  type        = string
  default     = "psql-cerohuella-qa"
}

variable "postgresql_private_dns_zone_name" {
  description = "Private DNS zone for PostgreSQL."
  type        = string
  default     = "pdz-cerohuella-qa.postgres.database.azure.com"
}

variable "postgresql_version" {
  description = "PostgreSQL version."
  type        = string
  default     = "16"
}

variable "postgresql_sku_name" {
  description = "PostgreSQL SKU."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB."
  type        = number
  default     = 32768
}

variable "postgresql_backup_retention_days" {
  description = "PostgreSQL backup retention in days."
  type        = number
  default     = 7
}

variable "database_name" {
  description = "Application database name."
  type        = string
  default     = "cerohuella"
}

variable "postgres_admin_login" {
  description = "PostgreSQL administrator login."
  type        = string
  default     = "lpari"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password."
  type        = string
  sensitive   = true
}

variable "create_action_group" {
  description = "Whether to create an Azure Monitor action group."
  type        = bool
  default     = false
}

variable "action_group_name" {
  description = "Action group name."
  type        = string
  default     = "ag-cerohuella-qa"
}

variable "action_group_short_name" {
  description = "Action group short name."
  type        = string
  default     = "chqa"
}

variable "alert_email_receivers" {
  description = "Alert email receivers."
  type        = map(string)
  default     = {}
}

variable "alert_webhook_receivers" {
  description = "Alert webhook receivers."
  type        = map(string)
  default     = {}
}

variable "container_cpu_alert_threshold" {
  description = "Container App CPU alert threshold."
  type        = number
  default     = 80
}

variable "postgresql_cpu_alert_threshold" {
  description = "PostgreSQL CPU alert threshold."
  type        = number
  default     = 80
}

