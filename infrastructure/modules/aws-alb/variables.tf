# =============================================================================
# infrastructure/modules/aws-alb/variables.tf
# =============================================================================
# LegendForge AWS Alb variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "public_subnet_ids" {
  description = "Subnet identifier values used by LegendForge infrastructure for public subnet ids."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Provider resource ID used by LegendForge infrastructure for alb security group id."
  type        = string
}

variable "certificate_arn" {
  description = "AWS ARN used by LegendForge infrastructure for certificate arn."
  type        = string
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
