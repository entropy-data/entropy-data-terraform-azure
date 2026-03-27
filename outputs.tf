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
