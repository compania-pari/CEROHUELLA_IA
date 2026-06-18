variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "create_action_group" {
  description = "Whether to create an action group and attach it to metric alerts."
  type        = bool
  default     = false
}

variable "action_group_name" {
  description = "Monitor action group name."
  type        = string
  default     = "ag-cerohuella"
}

variable "action_group_short_name" {
  description = "Monitor action group short name."
  type        = string
  default     = "cerohuella"
}

variable "email_receivers" {
  description = "Email receivers keyed by receiver name."
  type        = map(string)
  default     = {}
}

variable "webhook_receivers" {
  description = "Webhook receivers keyed by receiver name."
  type        = map(string)
  default     = {}
}

variable "metric_alerts" {
  description = "Metric alerts keyed by logical alert name."
  type = map(object({
    name             = string
    scopes           = list(string)
    description      = optional(string, null)
    severity         = optional(number, 3)
    frequency        = optional(string, "PT1M")
    window_size      = optional(string, "PT5M")
    enabled          = optional(bool, true)
    metric_namespace = string
    metric_name      = string
    aggregation      = string
    operator         = string
    threshold        = number
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to monitor resources."
  type        = map(string)
  default     = {}
}

