# =============================================================================
# infrastructure/modules/azure/monitoring/variables.tf
# =============================================================================
# LegendForge Monitoring variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "log_retention_days" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 30
}

variable "metric_alert_email" {
  description = "Email address for metric alerts for LegendForge's universal tabletop infrastructure."
  type        = string
}

variable "scale_set_id" {
  description = "Provider resource ID used by LegendForge infrastructure for scale set id."
  type        = string
}

variable "load_balancer_id" {
  description = "Provider resource ID used by LegendForge infrastructure for load balancer id."
  type        = string
}

variable "storage_account_id" {
  description = "Provider resource ID used by LegendForge infrastructure for storage account id."
  type        = string
}

variable "database_server_id" {
  description = "Provider resource ID used by LegendForge infrastructure for database server id."
  type        = string
}

variable "key_vault_id" {
  description = "Provider resource ID used by LegendForge infrastructure for key vault id."
  type        = string
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
