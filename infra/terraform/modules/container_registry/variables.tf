variable "name" {
  description = "Azure Container Registry name."
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

variable "sku" {
  description = "ACR SKU."
  type        = string
  default     = "Basic"
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled for ACR."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to ACR."
  type        = map(string)
  default     = {}
}

