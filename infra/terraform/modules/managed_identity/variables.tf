variable "name" {
  description = "User-assigned managed identity name."
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

variable "acr_id" {
  description = "ACR resource ID. When set, AcrPull is granted to the identity."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the managed identity."
  type        = map(string)
  default     = {}
}

