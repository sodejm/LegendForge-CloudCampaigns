# =============================================================================
# infrastructure/modules/aws-cloudwatch/variables.tf
# =============================================================================
# LegendForge AWS Cloudwatch variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "log_retention_days" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 30
}

variable "rds_instance_id" {
  description = "Provider resource ID used by LegendForge infrastructure for rds instance id."
  type        = string
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
