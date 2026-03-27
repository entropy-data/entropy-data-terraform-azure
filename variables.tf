variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "application_name" {
  description = "Name of the application (used as prefix for resource names and resource group name)"
  type        = string
}

variable "container_image" {
  description = "Container image for entropy-data"
  type        = string
}

variable "container_cpu" {
  description = "CPU cores allocated to the container app"
  type        = number
  default     = 2
}

variable "container_memory" {
  description = "Memory allocated to the container app (e.g., '2Gi')"
  type        = string
  default     = "4Gi"
}

variable "spring_profiles_active" {
  description = "Active Spring profiles for the application"
  type        = string
}

variable "application_host_web" {
  description = "Public web URL used by entropy-data in generated links"
  type        = string
}

variable "mail_host" {
  description = "SMTP server host"
  type        = string
  default     = null
}

variable "mail_port" {
  description = "SMTP server port"
  type        = string
  default     = null
}

variable "mail_username" {
  description = "SMTP username"
  type        = string
  default     = null
}

variable "mail_properties_mail_smtp_auth" {
  description = "Whether SMTP auth is enabled"
  type        = string
  default     = "true"
}

variable "mail_properties_mail_smtp_starttls_enable" {
  description = "Whether SMTP STARTTLS is enabled"
  type        = string
  default     = "true"
}

variable "application_mail_from" {
  description = "Sender email address"
  type        = string
}

# Azure SSO (optional)
variable "sso_azure_enabled" {
  description = "Enable Azure SSO environment variables"
  type        = bool
  default     = false
}

variable "sso_azure_issuer_uri" {
  description = "OIDC issuer URI for Azure SSO"
  type        = string
  default     = null
}

variable "sso_azure_client_id" {
  description = "Client ID for Azure SSO"
  type        = string
  default     = null
  sensitive   = true
}

variable "sso_azure_client_secret" {
  description = "Client secret for Azure SSO"
  type        = string
  default     = null
  sensitive   = true
}

variable "sso_azure_hosts" {
  description = "Comma-separated hostnames for Azure SSO (without protocol); defaults to application_host_web host"
  type        = string
  default     = null
}

variable "additional_env_vars" {
  description = "Additional environment variables for the container app"
  type        = map(string)
  default     = {}
}

# Container Registry
variable "container_registry_server" {
  description = "Container registry server URL (optional for anonymous public pulls)"
  type        = string
  default     = null
}

variable "container_registry_username" {
  description = "Container registry username (optional for anonymous public pulls)"
  type        = string
  default     = null
}

variable "container_registry_password" {
  description = "Container registry password (optional for anonymous public pulls)"
  type        = string
  default     = null
  sensitive   = true
}

# Azure OpenAI
variable "azure_openai_endpoint" {
  description = "Azure OpenAI endpoint"
  type        = string
}

variable "azure_openai_deployment_name" {
  description = "Azure OpenAI deployment name"
  type        = string
}

variable "azure_openai_key" {
  description = "Azure OpenAI API key"
  type        = string
  sensitive   = true
}

# PostgreSQL
variable "postgres_sku" {
  description = "SKU for the PostgreSQL Flexible Server"
  type        = string
  default     = "GP_Standard_D2s_v3"

  validation {
    condition = contains([
      "B_Standard_B1ms", "B_Standard_B2s", "B_Standard_B2ms", "GP_Standard_D4ds_v5",
      "GP_Standard_D2s_v3", "GP_Standard_D4s_v3", "GP_Standard_D8s_v3", "GP_Standard_D16s_v3",
      "GP_Standard_D32s_v3", "GP_Standard_D48s_v3", "GP_Standard_D64s_v3", "GP_Standard_D2ds_v5",
      "MO_Standard_E2s_v3", "MO_Standard_E4s_v3", "MO_Standard_E8s_v3", "MO_Standard_E16s_v3",
      "MO_Standard_E20s_v3", "MO_Standard_E32s_v3", "MO_Standard_E48s_v3", "MO_Standard_E64s_v3"
    ], var.postgres_sku)
    error_message = "Invalid SKU. Please choose from the available options."
  }
}

variable "postgres_storage_gb" {
  description = "Storage size for PostgreSQL in GB. Minimum is 32GB, maximum is 16384GB"
  type        = number
  default     = 128

  validation {
    condition     = var.postgres_storage_gb >= 32 && var.postgres_storage_gb <= 16384
    error_message = "Storage size must be between 32GB and 16384GB."
  }
}

variable "postgres_storage_tier" {
  description = "Storage tier for PostgreSQL"
  type        = string
  default     = "P10"
}

# Secrets
variable "smtp_password" {
  description = "SMTP server password"
  type        = string
  default     = null
  sensitive   = true
}

# Azure Communication Services Email over SMTP (optional)
variable "acs_email_enabled" {
  description = "Enable Azure Communication Services SMTP settings for email"
  type        = bool
  default     = false
}

variable "acs_data_location" {
  description = "Data location for Azure Communication Services resources"
  type        = string
  default     = "Europe"
}

variable "acs_communication_service_name" {
  description = "Optional name for the Azure Communication Service resource"
  type        = string
  default     = null
}

variable "acs_email_service_name" {
  description = "Optional name for the Azure Email Communication Service resource"
  type        = string
  default     = null
}

variable "acs_managed_domain_name" {
  description = "Email domain resource name for Azure Email Communication Service"
  type        = string
  default     = "AzureManagedDomain"
}

variable "acs_sender_username" {
  description = "Sender username to create in the ACS managed email domain"
  type        = string
  default     = "noreply"
}

variable "acs_smtp_host" {
  description = "ACS SMTP host"
  type        = string
  default     = "smtp.azurecomm.net"
}

variable "acs_smtp_port" {
  description = "ACS SMTP port"
  type        = string
  default     = "587"
}

variable "acs_smtp_username" {
  description = "ACS SMTP username"
  type        = string
  default     = null
}

variable "acs_smtp_password" {
  description = "ACS SMTP password"
  type        = string
  default     = null
  sensitive   = true
}

variable "acs_smtp_password_key_vault_id" {
  description = "Optional Azure Key Vault ID used to read ACS SMTP password"
  type        = string
  default     = null
}

variable "acs_smtp_password_secret_name" {
  description = "Optional Key Vault secret name for ACS SMTP password"
  type        = string
  default     = null
}

variable "acs_smtp_password_secret_version" {
  description = "Optional Key Vault secret version for ACS SMTP password"
  type        = string
  default     = null
}

variable "acs_mail_from" {
  description = "Sender email address when ACS email mode is enabled"
  type        = string
  default     = null
}
