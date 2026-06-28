# =============================================================================
# infrastructure/modules/azure/security/main.tf
# =============================================================================
# LegendForge Security module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

resource "random_id" "kv" {
  byte_length = 4
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                            = "kv-${var.project_name}-${random_id.kv.hex}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  tenant_id                       = var.tenant_id
  sku_name                        = "premium"
  soft_delete_retention_days      = 7
  purge_protection_enabled        = true
  public_network_access_enabled   = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

# Key Vault Access Policy
resource "azurerm_key_vault_access_policy" "main" {
  key_vault_id       = azurerm_key_vault.main.id
  tenant_id          = var.tenant_id
  object_id          = var.principal_id
  
  key_permissions = [
    "Get", "List", "Create", "Delete", "Recover", "Backup", "Restore", "Decrypt", "Encrypt", "Update"
  ]
  
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
  ]
  
  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Recover", "Backup", "Restore"
  ]
}

# Store secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name            = replace(each.key, "_", "-")
  value           = each.value
  key_vault_id    = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.main]
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-keyvault-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.storage_subnet_id

  private_service_connection {
    name                           = "psc-keyvault"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
  }

  tags = var.tags
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.vnet_id
}

# DNS A Record for Key Vault Private Endpoint
resource "azurerm_private_dns_a_record" "keyvault" {
  name                = azurerm_key_vault.main.name
  zone_name           = azurerm_private_dns_zone.keyvault.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address]
}

# Allow Key Vault through firewall
resource "azurerm_key_vault_network_rule" "main" {
  key_vault_id = azurerm_key_vault.main.id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = []
  ip_rules                   = []

  depends_on = [azurerm_key_vault_access_policy.main]
}
