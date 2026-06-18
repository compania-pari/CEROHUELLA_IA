output "resource_group_name" {
  description = "Shared resource group name."
  value       = module.resource_group.name
}

output "acr_id" {
  description = "Shared ACR ID."
  value       = module.container_registry.id
}

output "acr_name" {
  description = "Shared ACR name."
  value       = module.container_registry.name
}

output "acr_login_server" {
  description = "Shared ACR login server."
  value       = module.container_registry.login_server
}

