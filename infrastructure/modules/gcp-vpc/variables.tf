# =============================================================================
# infrastructure/modules/gcp-vpc/variables.tf
# =============================================================================
# LegendForge GCP Vpc variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "secondary_region" {
  description = "Secondary region used for LegendForge disaster recovery or multi-region failover."
  type        = string
  default     = "us-east1"
}

variable "primary_subnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for primary subnet cidr."
  type        = string
  default     = "10.0.0.0/20"
}

variable "secondary_subnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for secondary subnet cidr."
  type        = string
  default     = "10.16.0.0/20"
}

variable "enable_secondary_subnet" {
  description = "Whether to enable secondary subnet for LegendForge's universal tabletop platform."
  type        = bool
  default     = false
}

variable "admin_source_ranges" {
  description = "List of CIDR ranges allowed for SSH admin access for LegendForge's universal tabletop infrastructure."
  type        = list(string)
  default     = ["0.0.0.0/0"] # IMPORTANT: Restrict this in production!
}
