# =============================================================================
# infrastructure/deployments/azure/main.tf
# =============================================================================
# LegendForge Azure deployment configuration for universal tabletop infrastructure with multi-system support.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# BUILT ON:
# - Foundry VTT: https://github.com/foundryvtt
# - felddy/foundryvtt Docker: https://github.com/felddy/foundryvtt-docker
# - Cloudflare Tunnel: https://www.cloudflare.com/products/tunnel/
# - Terraform: https://www.terraform.io/
# - Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm/
#
# This configuration leverages excellent open-source and community projects.
# See ATTRIBUTION.md for full credits.
# =============================================================================

terraform {
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
  skip_provider_registration = false
}

provider "random" {}

# Networking Module for LegendForge multi-system operations.
module "networking" {
  source = "../../modules/azure/networking"

  environment        = var.environment
  location           = var.location
  project_name       = var.project_name
  vnet_address_space = var.vnet_address_space

  tags = merge(var.common_tags, {
    Module = "networking"
  })
}

# Security Module (Key Vault) for LegendForge multi-system operations.
module "security" {
  source = "../../modules/azure/security"

  environment         = var.environment
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  project_name        = var.project_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  principal_id        = data.azurerm_client_config.current.object_id
  vnet_id             = module.networking.vnet_id
  storage_subnet_id   = module.networking.storage_subnet_id

  secrets = {
    foundry_license_key = var.foundry_license_key
    database_password   = var.database_password
    storage_account_key = module.storage.storage_account_primary_access_key
  }

  tags = merge(var.common_tags, {
    Module = "security"
  })

  depends_on = [module.storage]
}

# Storage Module for LegendForge multi-system operations.
module "storage" {
  source = "../../modules/azure/storage"

  environment                   = var.environment
  location                      = var.location
  resource_group_name           = module.networking.resource_group_name
  project_name                  = var.project_name
  vnet_id                       = module.networking.vnet_id
  app_subnet_id                 = module.networking.app_subnet_id
  managed_identity_principal_id = module.compute.managed_identity_principal_id
  enable_cdn                    = var.enable_cdn

  tags = merge(var.common_tags, {
    Module = "storage"
  })
}

# Database Module for LegendForge multi-system operations.
module "database" {
  source = "../../modules/azure/database"

  environment                  = var.environment
  location                     = var.location
  resource_group_name          = module.networking.resource_group_name
  project_name                 = var.project_name
  database_subnet_id           = module.networking.database_subnet_id
  vnet_id                      = module.networking.vnet_id
  admin_username               = var.database_admin_username
  admin_password               = var.database_password
  db_engine                    = var.database_engine
  db_version                   = var.database_version
  db_sku_name                  = var.database_sku_name
  db_storage_size              = var.database_storage_size
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  high_availability_enabled    = var.high_availability_enabled

  tags = merge(var.common_tags, {
    Module = "database"
  })
}

# Compute Module (VMs, Scale Sets, Load Balancer) for LegendForge multi-system operations.
module "compute" {
  source = "../../modules/azure/compute"

  environment            = var.environment
  location               = var.location
  resource_group_name    = module.networking.resource_group_name
  project_name           = var.project_name
  app_subnet_id          = module.networking.app_subnet_id
  app_nsg_id             = module.networking.app_nsg_id
  vm_size                = var.vm_size
  scale_set_capacity     = var.scale_set_capacity
  scale_set_min_capacity = var.scale_set_min_capacity
  scale_set_max_capacity = var.scale_set_max_capacity
  admin_username         = var.vm_admin_username
  ssh_public_key         = var.vm_ssh_public_key
  foundry_version        = var.foundry_version
  foundry_license_key    = var.foundry_license_key
  database_host          = module.database.mysql_server_fqdn
  database_name          = var.project_name
  storage_account_name   = module.storage.storage_account_name
  storage_account_key    = module.storage.storage_account_primary_access_key
  key_vault_uri          = module.security.key_vault_uri

  tags = merge(var.common_tags, {
    Module = "compute"
  })

  depends_on = [module.database, module.storage]
}

# Monitoring Module for LegendForge multi-system operations.
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "../../modules/azure/monitoring"

  environment         = var.environment
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  project_name        = var.project_name
  metric_alert_email  = var.alert_email
  scale_set_id        = module.compute.scale_set_id
  load_balancer_id    = module.compute.load_balancer_id
  storage_account_id  = module.storage.storage_account_id
  database_server_id  = module.database.mysql_server_id
  key_vault_id        = module.security.key_vault_id

  tags = merge(var.common_tags, {
    Module = "monitoring"
  })

  depends_on = [module.compute, module.storage, module.database, module.security]
}

# Get current Azure context
data "azurerm_client_config" "current" {}
