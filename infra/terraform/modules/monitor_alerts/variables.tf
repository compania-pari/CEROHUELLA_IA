variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region for scheduled query alerts."
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

variable "scheduled_query_alerts" {
  description = "Scheduled query alerts keyed by logical alert name."
  type = map(object({
    name                    = string
    scopes                  = list(string)
    description             = optional(string, null)
    severity                = optional(number, 3)
    evaluation_frequency    = optional(string, "PT5M")
    window_duration         = optional(string, "PT5M")
    enabled                 = optional(bool, true)
    skip_query_validation   = optional(bool, true)
    query                   = string
    time_aggregation_method = string
    metric_measure_column   = optional(string, null)
    resource_id_column      = optional(string, null)
    operator                = string
    threshold               = number
    dimensions = optional(list(object({
      name     = string
      operator = string
      values   = list(string)
    })), [])
    failing_periods = optional(object({
      minimum_failing_periods_to_trigger_alert = number
      number_of_evaluation_periods             = number
      }), {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    })
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to monitor resources."
  type        = map(string)
  default     = {}
}
