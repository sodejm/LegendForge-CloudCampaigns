# =============================================================================
# infrastructure/modules/azure/security/variables.tf
# =============================================================================
# LegendForge Security variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "tenant_id" {
  description = "Provider resource ID used by LegendForge infrastructure for tenant id."
  type        = string
}

variable "principal_id" {
  description = "Provider resource ID used by LegendForge infrastructure for principal id."
  type        = string
}

variable "vnet_id" {
  description = "Virtual network identifier used by LegendForge infrastructure resources."
  type        = string
}

variable "storage_subnet_id" {
  description = "Subnet identifier values used by LegendForge infrastructure for storage subnet id."
  type        = string
}

variable "secrets" {
  description = "Security setting used to protect LegendForge's multi-system platform."
  type        = map(string)
  sensitive   = true
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
