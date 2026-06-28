# =============================================================================
# infrastructure/modules/aws-security-groups/variables.tf
# =============================================================================
# LegendForge AWS Security Groups variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier used by LegendForge networked infrastructure resources."
  type        = string
}

variable "admin_ssh_cidr" {
  description = "Optional break-glass CIDR allowed to administer LegendForge infrastructure over SSH."
  type        = string
  default     = null
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
