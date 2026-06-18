variable "name" {
  description = "Application Insights name."
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

variable "workspace_id" {
  description = "Log Analytics workspace resource ID."
  type        = string
}

variable "application_type" {
  description = "Application Insights type."
  type        = string
  default     = "web"
}

variable "tags" {
  description = "Tags applied to Application Insights."
  type        = map(string)
  default     = {}
}

