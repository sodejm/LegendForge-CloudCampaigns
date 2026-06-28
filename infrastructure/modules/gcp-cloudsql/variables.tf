# =============================================================================
# infrastructure/modules/gcp-cloudsql/variables.tf
# =============================================================================
# LegendForge GCP Cloudsql variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
}

variable "primary_region" {
  description = "Primary region for LegendForge production traffic and stateful services."
  type        = string
  default     = "us-central1"
}

variable "replica_region" {
  description = "Secondary region used for LegendForge read replicas or disaster recovery."
  type        = string
  default     = "us-east1"
}

variable "database_version" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "POSTGRES_15"
}

variable "machine_type" {
  description = "Compute machine type used for LegendForge platform services."
  type        = string
  default     = "db-custom-2-7680" # 2 CPU, 7.5 GB RAM - good for small Foundry servers
}

variable "max_connections" {
  description = "PostgreSQL max_connections parameter for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "200"
}

variable "shared_buffers" {
  description = "PostgreSQL shared_buffers in MB for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "2048" # For 7.5 GB RAM instance
}

variable "effective_cache_size" {
  description = "PostgreSQL effective_cache_size in MB for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "6144" # For 7.5 GB RAM instance
}

variable "foundry_database_name" {
  description = "Resource name used by LegendForge infrastructure for foundry database name."
  type        = string
  default     = "foundry"
}

variable "foundry_db_user" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "foundry_app"
}

variable "foundry_backup_user" {
  description = "Username for backup and monitoring user for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "foundry_backup"
}

variable "vpc_network_id" {
  description = "Provider resource ID used by LegendForge infrastructure for vpc network id."
  type        = string
}

variable "primary_subnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for primary subnet cidr."
  type        = string
  default     = "10.0.0.0/20"
}

variable "enable_public_ip" {
  description = "Whether to enable public ip for LegendForge's universal tabletop platform."
  type        = bool
  default     = false
}

variable "enable_read_replica" {
  description = "Whether to enable read replica for LegendForge's universal tabletop platform."
  type        = bool
  default     = false
}

variable "enable_automated_backups" {
  description = "Whether to enable automated backups for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection for production for LegendForge's universal tabletop infrastructure."
  type        = bool
  default     = true
}

variable "backup_location" {
  description = "Cloud SQL backup location (multi-region for HA) for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "us"
}

variable "labels" {
  description = "Labels applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    app         = "legendforge"
    environment = "production"
    managed_by  = "terraform"
  }
}
