# =============================================================================
# infrastructure/deployments/azure/variables.tf
# =============================================================================
# LegendForge Azure deployment configuration for universal tabletop infrastructure with multi-system support.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region where LegendForge's multi-system tabletop infrastructure is deployed."
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
  default     = "legendforge"
}

variable "vnet_address_space" {
  description = "Virtual network address space for LegendForge's universal tabletop infrastructure."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# LegendForge Configuration
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

# Database Configuration
variable "database_engine" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "mysql"
}

variable "database_version" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "8.0"
}

variable "database_sku_name" {
  description = "Resource name used by LegendForge infrastructure for database sku name."
  type        = string
  default     = "Standard_B2s"
}

variable "database_storage_size" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 100
}

variable "database_admin_username" {
  description = "Administrative database username used to provision LegendForge stateful services."
  type        = string
  default     = "azureadmin"
}

variable "database_password" {
  description = "Database password used by LegendForge stateful services and supporting multi-system data workloads."
  type        = string
  sensitive   = true
}

variable "backup_retention_days" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 35
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups for LegendForge's universal tabletop infrastructure."
  type        = bool
  default     = true
}

variable "high_availability_enabled" {
  description = "Enable database high availability for LegendForge's universal tabletop infrastructure."
  type        = bool
  default     = true
}

# Compute Configuration
variable "vm_size" {
  description = "Azure VM size used for LegendForge application nodes."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "scale_set_capacity" {
  description = "Initial VM scale set capacity for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

variable "scale_set_min_capacity" {
  description = "Minimum VM scale set capacity for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

variable "scale_set_max_capacity" {
  description = "Maximum VM scale set capacity for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 10
}

variable "vm_admin_username" {
  description = "Administrator username used for break-glass access to LegendForge compute resources."
  type        = string
  default     = "azureuser"
}

variable "vm_ssh_public_key" {
  description = "Public SSH key used for break-glass administration of LegendForge compute resources."
  type        = string
}

# Monitoring
variable "enable_monitoring" {
  description = "Whether to enable monitoring for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email destination for LegendForge operational alerts."
  type        = string
}

# Storage
variable "enable_cdn" {
  description = "Whether to enable cdn for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common metadata tags applied to all LegendForge infrastructure resources."
  type        = map(string)
  default = {
    Project     = "LegendForge"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}
