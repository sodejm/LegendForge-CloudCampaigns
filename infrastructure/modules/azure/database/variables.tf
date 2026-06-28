# =============================================================================
# infrastructure/modules/azure/database/variables.tf
# =============================================================================
# LegendForge Database variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "database_subnet_id" {
  description = "Subnet identifier values used by LegendForge infrastructure for database subnet id."
  type        = string
}

variable "vnet_id" {
  description = "Virtual network identifier used by LegendForge infrastructure resources."
  type        = string
}

variable "admin_username" {
  description = "Administrator username used for break-glass access to LegendForge compute resources."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Database administrator password for LegendForge's universal tabletop infrastructure."
  type        = string
  sensitive   = true
}

variable "db_engine" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "mysql"
  validation {
    condition     = contains(["mysql", "postgres"], var.db_engine)
    error_message = "Database engine must be mysql or postgres."
  }
}

variable "db_version" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "8.0"
}

variable "db_storage_size" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 100
}

variable "db_sku_name" {
  description = "Resource name used by LegendForge infrastructure for db sku name."
  type        = string
  default     = "Standard_B2s"
}

variable "backup_retention_days" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 35
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup for LegendForge's universal tabletop infrastructure."
  type        = bool
  default     = true
}

variable "high_availability_enabled" {
  description = "Enable high availability for LegendForge's universal tabletop infrastructure."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
