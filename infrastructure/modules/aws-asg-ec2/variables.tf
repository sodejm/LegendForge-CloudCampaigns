# =============================================================================
# infrastructure/modules/aws-asg-ec2/variables.tf
# =============================================================================
# LegendForge AWS Asg Ec2 variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "private_subnet_ids" {
  description = "Subnet identifier values used by LegendForge infrastructure for private subnet ids."
  type        = list(string)
}

variable "asg_security_group_id" {
  description = "Provider resource ID used by LegendForge infrastructure for asg security group id."
  type        = string
}

variable "instance_profile_arn" {
  description = "AWS ARN used by LegendForge infrastructure for instance profile arn."
  type        = string
}

variable "target_group_arn" {
  description = "AWS ARN used by LegendForge infrastructure for target group arn."
  type        = string
}

variable "instance_type" {
  description = "Compute instance size used for LegendForge application nodes."
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 20
}

variable "data_volume_size" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 50
}

variable "min_size" {
  description = "Minimum number of instances for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

# LegendForge configuration
variable "foundry_hostname" {
  description = "Public LegendForge hostname that routes players to the Foundry-powered multi-system experience."
  type        = string
  sensitive   = true
}

variable "foundry_image" {
  description = "Container image for the Foundry VTT runtime that powers LegendForge, ideally pinned by digest."
  type        = string
  sensitive   = true
}

variable "cloudflared_image" {
  description = "Cloudflare Tunnel sidecar image used to publish LegendForge securely."
  type        = string
  default     = "cloudflare/cloudflared:latest"
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token that exposes LegendForge's multi-system service securely."
  type        = string
  sensitive   = true
}

variable "foundry_license_key" {
  description = "Foundry VTT license key consumed by the LegendForge application runtime."
  type        = string
  sensitive   = true
}

variable "foundry_admin_key" {
  description = "LegendForge administrator/setup password for the Foundry application runtime."
  type        = string
  sensitive   = true
}

# Database configuration
variable "db_host" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
}

variable "db_port" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Resource name used by LegendForge infrastructure for db name."
  type        = string
}

variable "db_username" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  sensitive   = true
}

# S3 and CloudWatch
variable "foundry_data_bucket" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = string
}

variable "cloudwatch_log_group" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = string
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
