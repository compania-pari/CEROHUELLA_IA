output "action_group_id" {
  description = "Action group ID when created."
  value       = var.create_action_group ? azurerm_monitor_action_group.this[0].id : null
}

output "metric_alert_ids" {
  description = "Metric alert IDs."
  value       = { for key, alert in azurerm_monitor_metric_alert.this : key => alert.id }
}

