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

locals {
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
        value = var.mail_host
      }

      env {
        name  = "SPRING_MAIL_PORT"
        value = var.mail_port
      }

      env {
        name  = "SPRING_MAIL_USERNAME"
        value = var.mail_username
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
        value = var.application_mail_from
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
    value = var.smtp_password
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
