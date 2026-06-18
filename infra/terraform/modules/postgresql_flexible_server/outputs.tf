output "id" {
  description = "PostgreSQL Flexible Server ID."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "name" {
  description = "PostgreSQL Flexible Server name."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "fqdn" {
  description = "PostgreSQL Flexible Server FQDN."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "database_name" {
  description = "Application database name."
  value       = azurerm_postgresql_flexible_server_database.this.name
}

output "private_dns_zone_id" {
  description = "PostgreSQL private DNS zone ID."
  value       = azurerm_private_dns_zone.postgresql.id
}

output "database_url_template" {
  description = "DATABASE_URL template without password."
  value       = "postgresql+psycopg://${var.administrator_login}:<password>@${azurerm_postgresql_flexible_server.this.fqdn}:5432/${azurerm_postgresql_flexible_server_database.this.name}"
  sensitive   = true
}

