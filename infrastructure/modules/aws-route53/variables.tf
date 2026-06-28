# =============================================================================
# infrastructure/modules/aws-route53/variables.tf
# =============================================================================
# LegendForge AWS Route53 variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
}

variable "zone_id" {
  description = "Provider resource ID used by LegendForge infrastructure for zone id."
  type        = string
}

variable "foundry_hostname" {
  description = "Public LegendForge hostname that routes players to the Foundry-powered multi-system experience."
  type        = string
}

variable "alb_dns_name" {
  description = "Resource name used by LegendForge infrastructure for alb dns name."
  type        = string
}

variable "alb_zone_id" {
  description = "Provider resource ID used by LegendForge infrastructure for alb zone id."
  type        = string
}

variable "create_health_check" {
  description = "Whether Terraform should create health check for LegendForge infrastructure."
  type        = bool
  default     = true
}

variable "create_certificate" {
  description = "Whether Terraform should create certificate for LegendForge infrastructure."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
