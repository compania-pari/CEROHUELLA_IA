output "virtual_network_id" {
  description = "Virtual network ID."
  value       = azurerm_virtual_network.this.id
}

output "virtual_network_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "container_apps_subnet_id" {
  description = "Container Apps subnet ID."
  value       = azurerm_subnet.container_apps.id
}

output "postgresql_subnet_id" {
  description = "PostgreSQL delegated subnet ID."
  value       = azurerm_subnet.postgresql.id
}

