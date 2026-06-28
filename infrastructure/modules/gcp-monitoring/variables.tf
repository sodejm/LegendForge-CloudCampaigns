# =============================================================================
# infrastructure/modules/gcp-monitoring/variables.tf
# =============================================================================
# LegendForge GCP Monitoring variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "instance_group_name" {
  description = "Resource name used by LegendForge infrastructure for instance group name."
  type        = string
}

variable "domain_name" {
  description = "Primary LegendForge domain used for certificates, ingress, and multi-system player access."
  type        = string
}

variable "gcp_project_id" {
  description = "Google Cloud project ID that hosts LegendForge's multi-system platform resources."
  type        = string
}

variable "database_instance_name" {
  description = "Resource name used by LegendForge infrastructure for database instance name."
  type        = string
}

variable "notification_channel_ids" {
  description = "Notification channel identifiers for LegendForge operational alerts."
  type        = list(string)
  default     = []
}
