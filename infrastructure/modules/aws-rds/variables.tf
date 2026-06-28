# =============================================================================
# infrastructure/modules/aws-rds/variables.tf
# =============================================================================
# LegendForge AWS Rds variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
}

variable "database_name" {
  description = "Primary database name used by LegendForge stateful services."
  type        = string
  default     = "foundry"
}

variable "database_username" {
  description = "Database username used by LegendForge stateful services."
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "Database password used by LegendForge stateful services and supporting multi-system data workloads."
  type        = string
  sensitive   = true
}

variable "database_subnet_ids" {
  description = "Subnet identifier values used by LegendForge infrastructure for database subnet ids."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Provider resource ID used by LegendForge infrastructure for rds security group id."
  type        = string
}

variable "postgres_version" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "15.3"
}

variable "instance_class" {
  description = "RDS instance class for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 100
}

variable "iops" {
  description = "Provisioned IOPS for gp3 for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 3000
}

variable "storage_throughput" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 125
}

variable "backup_retention_days" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default     = {}
}
