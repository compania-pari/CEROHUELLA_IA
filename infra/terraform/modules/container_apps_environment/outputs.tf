output "id" {
  description = "Container Apps Environment ID."
  value       = azurerm_container_app_environment.this.id
}

output "name" {
  description = "Container Apps Environment name."
  value       = azurerm_container_app_environment.this.name
}

output "default_domain" {
  description = "Default domain for apps in this environment."
  value       = azurerm_container_app_environment.this.default_domain
}

output "static_ip_address" {
  description = "Static IP address assigned to the environment."
  value       = azurerm_container_app_environment.this.static_ip_address
}

