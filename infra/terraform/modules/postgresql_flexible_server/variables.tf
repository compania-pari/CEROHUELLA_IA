variable "name" {
  description = "PostgreSQL Flexible Server name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "postgresql_version" {
  description = "PostgreSQL version."
  type        = string
  default     = "16"
}

variable "delegated_subnet_id" {
  description = "Delegated subnet ID for PostgreSQL Flexible Server."
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network ID linked to the PostgreSQL private DNS zone."
  type        = string
}

variable "private_dns_zone_name" {
  description = "Private DNS zone name for PostgreSQL Flexible Server."
  type        = string
}

variable "administrator_login" {
  description = "PostgreSQL administrator login."
  type        = string
}

variable "administrator_password" {
  description = "PostgreSQL administrator password."
  type        = string
  sensitive   = true
}

variable "zone" {
  description = "Availability zone."
  type        = string
  default     = "1"
}

variable "storage_mb" {
  description = "Storage size in MB."
  type        = number
  default     = 32768
}

variable "sku_name" {
  description = "PostgreSQL Flexible Server SKU."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "backup_retention_days" {
  description = "Backup retention in days."
  type        = number
  default     = 7
}

variable "database_name" {
  description = "Application database name."
  type        = string
  default     = "cerohuella"
}

variable "database_charset" {
  description = "Database charset."
  type        = string
  default     = "UTF8"
}

variable "database_collation" {
  description = "Database collation."
  type        = string
  default     = "en_US.utf8"
}

variable "tags" {
  description = "Tags applied to PostgreSQL resources."
  type        = map(string)
  default     = {}
}

