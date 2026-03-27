# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.application_name}-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1
}
