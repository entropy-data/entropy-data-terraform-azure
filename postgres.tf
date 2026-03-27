locals {
  postgres_admin_username = "edadmin"
}

# Random password for PostgreSQL
resource "random_password" "postgres_password" {
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                          = "${var.application_name}-postgres"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.postgres.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  zone                          = 2

  administrator_login    = local.postgres_admin_username
  administrator_password = random_password.postgres_password.result

  storage_mb        = var.postgres_storage_gb * 1024
  storage_tier      = var.postgres_storage_tier
  auto_grow_enabled = true

  sku_name              = var.postgres_sku
  backup_retention_days = 28

  maintenance_window {
    day_of_week  = 0 # Sunday
    start_hour   = 4 # 4 AM UTC
    start_minute = 0
  }

  authentication {
    password_auth_enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Enable PostgreSQL extensions
resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "vector,uuid-ossp,hstore,pg_stat_statements"
}

# Enable Query Store and performance monitoring
resource "azurerm_postgresql_flexible_server_configuration" "query_capture_mode" {
  name      = "pg_qs.query_capture_mode"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "all"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgms_wait_sampling_query_capture_mode" {
  name      = "pgms_wait_sampling.query_capture_mode"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "all"
}

resource "azurerm_postgresql_flexible_server_configuration" "track_activities" {
  name      = "track_activities"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "track_counts" {
  name      = "track_counts"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "track_io_timing" {
  name      = "track_io_timing"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "track_functions" {
  name      = "track_functions"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "all"
}

resource "azurerm_postgresql_flexible_server_configuration" "pg_stat_statements_track" {
  name      = "pg_stat_statements.track"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "top"
}

# Configure PostgreSQL diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "postgres" {
  name                       = "${var.application_name}-postgres-diag"
  target_resource_id         = azurerm_postgresql_flexible_server.postgres.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  enabled_log {
    category = "PostgreSQLFlexQueryStoreRuntime"
  }

  enabled_log {
    category = "PostgreSQLFlexQueryStoreWaitStats"
  }

  enabled_log {
    category = "PostgreSQLFlexSessions"
  }

  metric {
    category = "AllMetrics"
  }
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.application_name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.application_name}-postgres-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
}
