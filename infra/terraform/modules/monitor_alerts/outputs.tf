output "action_group_id" {
  description = "Action group ID when created."
  value       = var.create_action_group ? azurerm_monitor_action_group.this[0].id : null
}

output "metric_alert_ids" {
  description = "Metric alert IDs."
  value       = { for key, alert in azurerm_monitor_metric_alert.this : key => alert.id }
}

output "scheduled_query_alert_ids" {
  description = "Scheduled query alert IDs."
  value       = { for key, alert in azurerm_monitor_scheduled_query_rules_alert_v2.this : key => alert.id }
}
