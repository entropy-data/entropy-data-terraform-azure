locals {
  acs_communication_service_name_effective = coalesce(var.acs_communication_service_name, "${var.application_name}-acs")
  acs_email_service_name_effective         = coalesce(var.acs_email_service_name, "${var.application_name}-email")
}

resource "azurerm_communication_service" "acs" {
  count = var.acs_email_enabled ? 1 : 0

  name                = local.acs_communication_service_name_effective
  resource_group_name = azurerm_resource_group.rg.name
  data_location       = var.acs_data_location
}

resource "azurerm_email_communication_service" "acs" {
  count = var.acs_email_enabled ? 1 : 0

  name                = local.acs_email_service_name_effective
  resource_group_name = azurerm_resource_group.rg.name
  data_location       = var.acs_data_location
}

resource "azurerm_email_communication_service_domain" "acs" {
  count = var.acs_email_enabled ? 1 : 0

  name              = var.acs_managed_domain_name
  email_service_id  = azurerm_email_communication_service.acs[0].id
  domain_management = "AzureManaged"
}

resource "azurerm_email_communication_service_domain_sender_username" "acs" {
  count = var.acs_email_enabled ? 1 : 0

  name                    = var.acs_sender_username
  email_service_domain_id = azurerm_email_communication_service_domain.acs[0].id
}
