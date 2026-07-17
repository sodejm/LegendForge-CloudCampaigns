# =============================================================================
# infrastructure/modules/azure/storage/main.tf
# =============================================================================
# LegendForge Storage module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

resource "random_string" "storage_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                       = "stg${replace(var.project_name, "-", "")}${random_string.storage_suffix.result}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  account_tier               = var.account_tier
  account_replication_type   = var.account_replication_type
  https_traffic_only_enabled = var.https_traffic_only_enabled
  min_tls_version            = var.min_tls_version
  shared_access_key_enabled  = true

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = []
  }

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "POST", "OPTIONS", "PUT", "DELETE"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = var.tags
}

# Storage Containers
resource "azurerm_storage_container" "foundry_data" {
  name                  = "foundry-data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "foundry_worlds" {
  name                  = "foundry-worlds"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "foundry_modules" {
  name                  = "foundry-modules"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "foundry_media" {
  name                  = "foundry-media"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Private Endpoint for Blob
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.app_subnet_id

  private_service_connection {
    name                           = "psc-blob"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
  }

  tags = var.tags
}

# Private DNS Zone for Blob
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "link-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.vnet_id
}

# DNS A Record for Blob Private Endpoint
resource "azurerm_private_dns_a_record" "blob" {
  name                = azurerm_storage_account.main.name
  zone_name           = azurerm_private_dns_zone.blob.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.blob.private_service_connection[0].private_ip_address]
}

# CDN Profile
resource "azurerm_cdn_profile" "main" {
  count               = var.enable_cdn ? 1 : 0
  name                = "cdn-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.cdn_sku
  tags                = var.tags
}

# CDN Endpoint for Media
resource "azurerm_cdn_endpoint" "media" {
  count               = var.enable_cdn ? 1 : 0
  name                = "cdn-media-${var.project_name}"
  profile_name        = azurerm_cdn_profile.main[0].name
  location            = var.location
  resource_group_name = var.resource_group_name
  origin_host_header  = azurerm_storage_account.main.primary_blob_host

  origin {
    name      = "storage"
    host_name = azurerm_storage_account.main.primary_blob_host
  }

  tags = var.tags
}

# Storage Account Access Policy - Grant managed identity access
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_principal_id
}

# Storage Account Access Policy - Grant managed identity read access
resource "azurerm_role_assignment" "storage_blob_data_reader" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.managed_identity_principal_id
}
