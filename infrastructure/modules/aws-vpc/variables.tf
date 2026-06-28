# =============================================================================
# infrastructure/modules/aws-vpc/variables.tf
# =============================================================================
# LegendForge AWS Vpc variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "vpc_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for vpc cidr."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones for LegendForge's universal tabletop infrastructure."
  type        = list(string)
  default     = []
}

variable "flow_logs_retention_days" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
