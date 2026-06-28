# =============================================================================
# infrastructure/modules/gcp-storage/variables.tf
# =============================================================================
# LegendForge GCP Storage variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
}

variable "primary_region" {
  description = "Primary region for LegendForge production traffic and stateful services."
  type        = string
  default     = "us-central1"
}

variable "backup_location" {
  description = "Multi-region location for backup bucket (us, eu, asia) for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "us"
}

variable "kms_key_id" {
  description = "Provider resource ID used by LegendForge infrastructure for kms key id."
  type        = string
  default     = ""
}

variable "foundry_compute_sa_email" {
  description = "Email of the LegendForge compute service account with multi-system support."
  type        = string
}

variable "labels" {
  description = "Labels applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    app         = "legendforge"
    environment = "production"
    managed_by  = "terraform"
  }
}
