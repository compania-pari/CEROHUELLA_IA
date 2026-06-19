variable "name" {
  description = "Container Apps Environment name."
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "Subnet ID for Container Apps Environment VNet integration."
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Whether the Container Apps Environment uses an internal load balancer."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the Container Apps Environment."
  type        = map(string)
  default     = {}
}

