# =============================================================================
# infrastructure/modules/gcp-secrets/variables.tf
# =============================================================================
# LegendForge GCP Secrets variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
}

variable "region" {
  description = "platform region where LegendForge's multi-system tabletop infrastructure is deployed."
  type        = string
  default     = "us"
}

variable "gcp_project_number" {
  description = "GCP project number for LegendForge's universal tabletop infrastructure."
  type        = string
}

variable "foundry_compute_sa_email" {
  description = "Email of LegendForge compute service account with multi-system support."
  type        = string
}

variable "database_password" {
  description = "Database password used by LegendForge stateful services and supporting multi-system data workloads."
  type        = string
  sensitive   = true
}

variable "foundry_license_key" {
  description = "Foundry VTT license key consumed by the LegendForge application runtime."
  type        = string
  sensitive   = true
}

variable "foundry_admin_key" {
  description = "LegendForge administrator/setup password for the Foundry application runtime."
  type        = string
  sensitive   = true
}

variable "foundry_username" {
  description = "Foundry account username used by LegendForge for authenticated runtime downloads when required."
  type        = string
  sensitive   = true
  default     = ""
}

variable "foundry_password" {
  description = "Foundry account password used by LegendForge for authenticated runtime downloads when required."
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token that exposes LegendForge's multi-system service securely."
  type        = string
  sensitive   = true
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
