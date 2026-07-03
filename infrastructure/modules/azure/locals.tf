# =============================================================================
# Azure Locals — Common values and naming conventions
# =============================================================================

locals {
  project = var.project_name
  env     = var.environment
  region  = var.azure_region

  # Azure naming convention (lowercase, hyphens)
  name_prefix = "${local.project}-${local.env}"

  # Common tags applied to all resources
  common_tags = {
    Project     = local.project
    Environment = local.env
    ManagedBy   = "Terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }

  # Networking defaults
  vnet_cidr           = var.vnet_cidr
  subnet_cidr         = var.subnet_cidr
  bastion_subnet_cidr = var.bastion_subnet_cidr

  # Compute defaults
  vm_size         = var.vm_size
  os_disk_size_gb = 30
}

# Data source: Latest Ubuntu 22.04 LTS image
data "azurerm_image" "ubuntu" {
  name                = "UbuntuServer2204LTS"
  resource_group_name = var.image_resource_group

  # Alternative: use marketplace image
  # This would be uncommented if using marketplace
  # publisher = "Canonical"
  # offer     = "0001-com-ubuntu-server-jammy"
  # sku       = "22_04-lts-gen2"
}
