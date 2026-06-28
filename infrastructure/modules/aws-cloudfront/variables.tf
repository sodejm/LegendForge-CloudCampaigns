# =============================================================================
# infrastructure/modules/aws-cloudfront/variables.tf
# =============================================================================
# LegendForge AWS Cloudfront variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
}

variable "assets_bucket_domain_name" {
  description = "Resource name used by LegendForge infrastructure for assets bucket domain name."
  type        = string
}

variable "alb_domain_name" {
  description = "Resource name used by LegendForge infrastructure for alb domain name."
  type        = string
}

variable "use_default_certificate" {
  description = "Security setting used to protect LegendForge's multi-system platform."
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "AWS ARN used by LegendForge infrastructure for acm certificate arn."
  type        = string
  default     = ""
}

variable "create_invalidation" {
  description = "Whether Terraform should create invalidation for LegendForge infrastructure."
  type        = bool
  default     = false
}

variable "invalidation_trigger" {
  description = "Trigger for CloudFront invalidation for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
