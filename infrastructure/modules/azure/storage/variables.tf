# =============================================================================
# infrastructure/modules/azure/storage/variables.tf
# =============================================================================
# LegendForge Storage variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "vnet_id" {
  description = "Virtual network identifier used by LegendForge infrastructure resources."
  type        = string
}

variable "app_subnet_id" {
  description = "Subnet identifier values used by LegendForge infrastructure for app subnet id."
  type        = string
}

variable "storage_subnet_id" {
  description = "Subnet identifier values used by LegendForge infrastructure for storage subnet id."
  type        = string
}

variable "account_tier" {
  description = "Storage account tier for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Storage replication type for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "GZRS"
}

variable "https_traffic_only_enabled" {
  description = "Enable HTTPS only for LegendForge's universal tabletop infrastructure."
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "TLS1_2"
}

variable "enable_cdn" {
  description = "Whether to enable cdn for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

variable "cdn_sku" {
  description = "CDN SKU for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "Standard_Microsoft"
}

variable "managed_identity_principal_id" {
  description = "Provider resource ID used by LegendForge infrastructure for managed identity principal id."
  type        = string
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
