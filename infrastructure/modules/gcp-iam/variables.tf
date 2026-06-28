# =============================================================================
# infrastructure/modules/gcp-iam/variables.tf
# =============================================================================
# LegendForge GCP Iam variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "gcp_project_id" {
  description = "Google Cloud project ID that hosts LegendForge's multi-system platform resources."
  type        = string
}

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
}
