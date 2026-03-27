# Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "${var.application_name}-env"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id
}

# 32 bytes = 64 hex chars, matching entropy-data encryption key requirements.
resource "random_id" "application_encryption_key" {
  byte_length = 32
}

resource "random_password" "spring_actuator_password" {
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
}

data "azurerm_key_vault_secret" "acs_smtp_password" {
  count = var.acs_email_enabled && var.acs_smtp_password == null && var.acs_smtp_password_key_vault_id != null && var.acs_smtp_password_secret_name != null ? 1 : 0

  key_vault_id = var.acs_smtp_password_key_vault_id
  name         = var.acs_smtp_password_secret_name
  version      = var.acs_smtp_password_secret_version
}

locals {
  effective_mail_host = var.acs_email_enabled ? var.acs_smtp_host : var.mail_host
  effective_mail_port = var.acs_email_enabled ? var.acs_smtp_port : var.mail_port

  effective_mail_username = var.acs_email_enabled ? coalesce(var.acs_smtp_username, var.acs_sender_username) : var.mail_username
  effective_mail_password = var.acs_email_enabled ? coalesce(var.acs_smtp_password, try(data.azurerm_key_vault_secret.acs_smtp_password[0].value, null)) : var.smtp_password

  effective_application_mail_from = var.acs_email_enabled ? coalesce(var.acs_mail_from, var.application_mail_from) : var.application_mail_from

  sso_azure_hosts_effective = coalesce(
    var.sso_azure_hosts,
    trimsuffix(trimprefix(trimprefix(var.application_host_web, "https://"), "http://"), "/")
  )
}

# Container App
resource "azurerm_container_app" "entropy_data" {
  name                         = var.application_name
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.entropy_data.id]
  }

  template {
    min_replicas = 1
    max_replicas = 10

    container {
      name   = "entropy-data"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "PORT"
        value = "8080"
      }

      env {
        name  = "SPRING_DATASOURCE_URL"
        value = "jdbc:postgresql://${azurerm_postgresql_flexible_server.postgres.name}.postgres.database.azure.com:5432/postgres"
      }

      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = local.postgres_admin_username
      }

      env {
        name  = "SPRING_DATASOURCE_PASSWORD"
        value = random_password.postgres_password.result
      }

      env {
        name        = "SPRING_MAIL_PASSWORD"
        secret_name = "smtp-password"
      }

      env {
        name  = "APPLICATION_HOST_WEB"
        value = var.application_host_web
      }

      env {
        name  = "SPRING_MAIL_HOST"
        value = local.effective_mail_host
      }

      env {
        name  = "SPRING_MAIL_PORT"
        value = local.effective_mail_port
      }

      env {
        name  = "SPRING_MAIL_USERNAME"
        value = local.effective_mail_username
      }

      env {
        name  = "SPRING_MAIL_PROPERTIES_MAIL_SMTP_AUTH"
        value = var.mail_properties_mail_smtp_auth
      }

      env {
        name  = "SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_ENABLE"
        value = var.mail_properties_mail_smtp_starttls_enable
      }

      env {
        name  = "APPLICATION_MAIL_FROM"
        value = local.effective_application_mail_from
      }

      dynamic "env" {
        for_each = var.sso_azure_enabled ? [1] : []
        content {
          name  = "SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_AZURE_ISSUER_URI"
          value = var.sso_azure_issuer_uri
        }
      }

      dynamic "env" {
        for_each = var.sso_azure_enabled ? [1] : []
        content {
          name        = "SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AZURESSO_CLIENT_ID"
          secret_name = "sso-azure-client-id"
        }
      }

      dynamic "env" {
        for_each = var.sso_azure_enabled ? [1] : []
        content {
          name        = "SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AZURESSO_CLIENT_SECRET"
          secret_name = "sso-azure-client-secret"
        }
      }

      dynamic "env" {
        for_each = var.sso_azure_enabled ? [1] : []
        content {
          name  = "SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AZURESSO_PROVIDER"
          value = "azure"
        }
      }

      dynamic "env" {
        for_each = var.sso_azure_enabled ? [1] : []
        content {
          name  = "SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AZURESSO_AUTHORIZATION_GRANT_TYPE"
          value = "authorization_code"
        }
      }

      dynamic "env" {
        for_each = var.sso_azure_enabled ? [1] : []
        content {
          name  = "SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AZURESSO_REDIRECT_URI"
          value = "{baseUrl}/{action}/oauth2/code/{registrationId}"
        }
      }

      dynamic "env" {
        for_each = var.sso_azure_enabled ? [1] : []
        content {
          name  = "SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AZURESSO_CLIENT_AUTHENTICATION_METHOD"
          value = "client_secret_basic"
        }
      }

      dynamic "env" {
        for_each = var.sso_azure_enabled ? [1] : []
        content {
          name  = "SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AZURESSO_SCOPE"
          value = "openid,profile,email"
        }
      }

      dynamic "env" {
        for_each = var.sso_azure_enabled ? [1] : []
        content {
          name  = "APPLICATION_SSO_AZURE_HOSTS"
          value = local.sso_azure_hosts_effective
        }
      }

      env {
        name        = "SPRING_ACTUATOR_PASSWORD"
        secret_name = "spring-actuator-password"
      }

      env {
        name        = "APPLICATION_ENCRYPTION_KEYS"
        secret_name = "application-encryption-keys"
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = var.spring_profiles_active
      }

      dynamic "env" {
        for_each = var.additional_env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      liveness_probe {
        port                    = 8080
        transport               = "HTTP"
        path                    = "/actuator/health/liveness"
        interval_seconds        = 5
        timeout                 = 5
        failure_count_threshold = 5
      }
      readiness_probe {
        port             = 8080
        transport        = "HTTP"
        path             = "/actuator/health/readiness"
        interval_seconds = 5
        timeout          = 3
      }
      startup_probe {
        port                    = 8080
        transport               = "HTTP"
        path                    = "/actuator/health/liveness"
        interval_seconds        = 10
        initial_delay           = 30
        failure_count_threshold = 30
      }
    }

    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = 50
    }

  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8080
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  dynamic "registry" {
    for_each = var.container_registry_server != null && var.container_registry_username != null && var.container_registry_password != null ? [1] : []
    content {
      server               = var.container_registry_server
      username             = var.container_registry_username
      password_secret_name = "container-registry-password"
    }
  }

  secret {
    name  = "postgres-password"
    value = random_password.postgres_password.result
  }

  secret {
    name  = "smtp-password"
    value = local.effective_mail_password
  }

  secret {
    name  = "azure-openai-key"
    value = var.azure_openai_key
  }

  secret {
    name  = "spring-actuator-password"
    value = random_password.spring_actuator_password.result
  }

  dynamic "secret" {
    for_each = var.sso_azure_enabled ? [1] : []
    content {
      name  = "sso-azure-client-id"
      value = var.sso_azure_client_id
    }
  }

  dynamic "secret" {
    for_each = var.sso_azure_enabled ? [1] : []
    content {
      name  = "sso-azure-client-secret"
      value = var.sso_azure_client_secret
    }
  }

  dynamic "secret" {
    for_each = var.container_registry_password != null ? [1] : []
    content {
      name  = "container-registry-password"
      value = var.container_registry_password
    }
  }

  secret {
    name  = "application-encryption-keys"
    value = upper(random_id.application_encryption_key.hex)
  }

  lifecycle {
    precondition {
      condition     = var.acs_email_enabled || (var.mail_host != null && var.mail_port != null && var.mail_username != null && var.smtp_password != null)
      error_message = "When acs_email_enabled is false, mail_host, mail_port, mail_username, and smtp_password must be set."
    }

    precondition {
      condition     = var.acs_email_enabled == false || (var.acs_smtp_password != null || (var.acs_smtp_password_key_vault_id != null && var.acs_smtp_password_secret_name != null))
      error_message = "When acs_email_enabled is true, provide either acs_smtp_password or both acs_smtp_password_key_vault_id and acs_smtp_password_secret_name."
    }

    precondition {
      condition     = (var.acs_smtp_password_key_vault_id == null && var.acs_smtp_password_secret_name == null) || (var.acs_smtp_password_key_vault_id != null && var.acs_smtp_password_secret_name != null)
      error_message = "Set both acs_smtp_password_key_vault_id and acs_smtp_password_secret_name together, or leave both unset."
    }

    precondition {
      condition     = var.sso_azure_enabled == false || (var.sso_azure_issuer_uri != null && var.sso_azure_client_id != null && var.sso_azure_client_secret != null)
      error_message = "When sso_azure_enabled is true, sso_azure_issuer_uri, sso_azure_client_id, and sso_azure_client_secret must be set."
    }

    ignore_changes = [
      ingress[0],
      template[0].container[0].image,
    ]
  }
}

resource "azurerm_user_assigned_identity" "entropy_data" {
  location            = azurerm_resource_group.rg.location
  name                = "entropy_data_containerapp_identity"
  resource_group_name = azurerm_resource_group.rg.name
}
