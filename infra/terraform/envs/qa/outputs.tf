output "container_app_name" {
  description = "Container App name."
  value       = module.container_app.name
}

output "container_app_latest_revision_fqdn" {
  description = "Latest revision FQDN."
  value       = module.container_app.latest_revision_fqdn
}

output "postgresql_fqdn" {
  description = "PostgreSQL FQDN."
  value       = module.postgresql.fqdn
}

output "database_name" {
  description = "Application database name."
  value       = module.postgresql.database_name
}

output "application_insights_connection_string" {
  description = "Application Insights connection string."
  value       = module.application_insights.connection_string
  sensitive   = true
}

output "managed_identity_client_id" {
  description = "Container App managed identity client ID."
  value       = module.managed_identity.client_id
}

