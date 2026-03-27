output "container_app_id" {
  description = "ID of the deployed entropy-data container app"
  value       = azurerm_container_app.entropy_data.id
}

output "container_app_environment_id" {
  description = "ID of the container app environment"
  value       = azurerm_container_app_environment.env.id
}

output "container_app_url" {
  description = "URL of the deployed entropy-data container app"
  value       = azurerm_container_app.entropy_data.ingress[0].fqdn
}

output "postgres_host" {
  description = "Hostname of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "container_apps_subnet_id" {
  description = "ID of the Container Apps subnet"
  value       = azurerm_subnet.container_apps.id
}

output "postgres_subnet_id" {
  description = "ID of the PostgreSQL subnet"
  value       = azurerm_subnet.postgres.id
}

output "acs_communication_service_id" {
  description = "ID of the Azure Communication Service (when ACS email mode is enabled)"
  value       = try(azurerm_communication_service.acs[0].id, null)
}

output "acs_communication_service_hostname" {
  description = "Hostname of the Azure Communication Service (when ACS email mode is enabled)"
  value       = try(azurerm_communication_service.acs[0].hostname, null)
}

output "acs_communication_service_primary_key" {
  description = "Primary key of the Azure Communication Service (sensitive)"
  value       = try(azurerm_communication_service.acs[0].primary_key, null)
  sensitive   = true
}

output "acs_email_communication_service_id" {
  description = "ID of the Azure Email Communication Service (when ACS email mode is enabled)"
  value       = try(azurerm_email_communication_service.acs[0].id, null)
}

output "acs_email_domain" {
  description = "Managed email domain used by ACS Email (when ACS email mode is enabled)"
  value       = try(azurerm_email_communication_service_domain.acs[0].name, null)
}

output "acs_email_sender_username" {
  description = "Sender username created in ACS Email domain (when ACS email mode is enabled)"
  value       = try(azurerm_email_communication_service_domain_sender_username.acs[0].name, null)
}
