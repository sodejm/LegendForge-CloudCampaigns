# =============================================================================
# infrastructure/modules/aws-s3/variables.tf
# =============================================================================
# LegendForge AWS S3 variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "Provider resource ID used by LegendForge infrastructure for cloudfront distribution id."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
