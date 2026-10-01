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

variable "enable_cloud_armor" {
  description = "Attach the Cloud Armor policy to the active Foundry backend. Disabling attachment retains the policy resource."
  type        = bool
  default     = true
}

variable "cloud_armor_preview" {
  description = "Preview WAF and rate-limit rules without blocking requests. Disable only after tuning and live acceptance."
  type        = bool
  default     = true
}

variable "cloud_armor_rate_limit_count" {
  description = "Requests per client IP per interval for the rate-based ban rule; tune for asset bursts and shared player IPs."
  type        = number
  default     = 100

  validation {
    condition     = var.cloud_armor_rate_limit_count >= 1 && var.cloud_armor_rate_limit_count <= 10000 && floor(var.cloud_armor_rate_limit_count) == var.cloud_armor_rate_limit_count
    error_message = "The rate-based ban count must be an integer from 1 through 10000."
  }
}

variable "cloud_armor_rate_limit_interval_sec" {
  description = "Cloud Armor rate-limit interval in seconds."
  type        = number
  default     = 60

  validation {
    condition     = contains([10, 30, 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600], var.cloud_armor_rate_limit_interval_sec)
    error_message = "The interval must be 10, 30, 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700 or 3600 seconds."
  }
}

variable "cloud_armor_ban_duration_sec" {
  description = "Additional ban duration after the rate-limit interval, in seconds."
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600], var.cloud_armor_ban_duration_sec)
    error_message = "The ban duration must be 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700 or 3600 seconds."
  }
}
