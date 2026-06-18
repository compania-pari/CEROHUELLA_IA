variable "virtual_network_name" {
  description = "Virtual network name."
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

variable "address_space" {
  description = "Virtual network address space."
  type        = list(string)
}

variable "container_apps_subnet_name" {
  description = "Container Apps subnet name."
  type        = string
}

variable "container_apps_subnet_prefixes" {
  description = "Container Apps subnet address prefixes."
  type        = list(string)
}

variable "postgresql_subnet_name" {
  description = "PostgreSQL delegated subnet name."
  type        = string
}

variable "postgresql_subnet_prefixes" {
  description = "PostgreSQL subnet address prefixes."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}

