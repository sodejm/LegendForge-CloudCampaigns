# =============================================================================
# infrastructure/modules/azure/compute/variables.tf
# =============================================================================
# LegendForge Compute variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
}

variable "location" {
  description = "Azure region where LegendForge's multi-system tabletop infrastructure is deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Azure resource group name that contains LegendForge infrastructure resources."
  type        = string
}

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
  default     = "legendforge"
}

variable "app_subnet_id" {
  description = "Subnet identifier values used by LegendForge infrastructure for app subnet id."
  type        = string
}

variable "app_nsg_id" {
  description = "Provider resource ID used by LegendForge infrastructure for app nsg id."
  type        = string
}

variable "vm_size" {
  description = "Azure VM size used for LegendForge application nodes."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "scale_set_capacity" {
  description = "Initial number of VMs in scale set for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

variable "scale_set_min_capacity" {
  description = "Minimum number of VMs in scale set for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

variable "scale_set_max_capacity" {
  description = "Maximum number of VMs in scale set for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 10
}

variable "os_image" {
  description = "OS image configuration for LegendForge's universal tabletop infrastructure."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

variable "admin_username" {
  description = "Administrator username used for break-glass access to LegendForge compute resources."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Security setting used to protect LegendForge's multi-system platform."
  type        = string
}

variable "foundry_version" {
  description = "Foundry VTT runtime version used by the LegendForge application tier."
  type        = string
  default     = "11.315"
}

variable "foundry_license_key" {
  description = "Foundry VTT license key consumed by the LegendForge application runtime."
  type        = string
  sensitive   = true
}

variable "database_host" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
}

variable "database_name" {
  description = "Primary database name used by LegendForge stateful services."
  type        = string
}

variable "storage_account_name" {
  description = "Resource name used by LegendForge infrastructure for storage account name."
  type        = string
}

variable "storage_account_key" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = string
  sensitive   = true
}

variable "key_vault_uri" {
  description = "Key Vault URI for LegendForge's universal tabletop infrastructure."
  type        = string
}

variable "enable_monitoring" {
  description = "Whether to enable Azure Monitor integration for LegendForge compute resources."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for LegendForge monitoring integration."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
