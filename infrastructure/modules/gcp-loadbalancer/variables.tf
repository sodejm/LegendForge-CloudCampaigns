# =============================================================================
# infrastructure/modules/gcp-loadbalancer/variables.tf
# =============================================================================
# LegendForge GCP Loadbalancer variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
}

variable "domain_name" {
  description = "Primary LegendForge domain used for certificates, ingress, and multi-system player access."
  type        = string
}

variable "instance_group_id" {
  description = "Provider resource ID used by LegendForge infrastructure for instance group id."
  type        = string
}

variable "health_check_id" {
  description = "Provider resource ID used by LegendForge infrastructure for health check id."
  type        = string
}

variable "enable_cdn" {
  description = "Whether to enable cdn for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

variable "enable_adaptive_protection" {
  description = "Whether to enable adaptive protection for LegendForge's universal tabletop platform."
  type        = bool
  default     = false
}
