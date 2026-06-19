output "id" {
  description = "Application Insights ID."
  value       = azurerm_application_insights.this.id
}

output "name" {
  description = "Application Insights name."
  value       = azurerm_application_insights.this.name
}

output "connection_string" {
  description = "Application Insights connection string."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

