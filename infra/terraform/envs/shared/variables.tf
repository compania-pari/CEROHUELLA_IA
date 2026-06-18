variable "location" {
  description = "Azure region for shared resources."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Shared resource group name."
  type        = string
  default     = "rg-cerohuella-shared"
}

variable "acr_name" {
  description = "Shared Azure Container Registry name."
  type        = string
  default     = "acrcerohuellashared"
}

variable "acr_sku" {
  description = "ACR SKU."
  type        = string
  default     = "Basic"
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

