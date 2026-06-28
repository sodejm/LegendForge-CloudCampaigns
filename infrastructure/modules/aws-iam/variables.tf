# =============================================================================
# infrastructure/modules/aws-iam/variables.tf
# =============================================================================
# LegendForge AWS Iam variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
}

variable "aws_region" {
  description = "AWS region where LegendForge's multi-system tabletop infrastructure is deployed."
  type        = string
}

variable "foundry_data_bucket_arn" {
  description = "AWS ARN used by LegendForge infrastructure for foundry data bucket arn."
  type        = string
}

variable "cloudfront_assets_bucket_arn" {
  description = "AWS ARN used by LegendForge infrastructure for cloudfront assets bucket arn."
  type        = string
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
