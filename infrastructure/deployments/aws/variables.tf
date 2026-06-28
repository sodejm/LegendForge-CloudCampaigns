# =============================================================================
# infrastructure/deployments/aws/variables.tf
# =============================================================================
# LegendForge AWS deployment configuration for universal tabletop infrastructure with multi-system support.
# Supports LegendForge's universal tabletop platform across multiple game systems.

variable "aws_region" {
  description = "AWS region where LegendForge's multi-system tabletop infrastructure is deployed."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
  default     = "prod"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    Project = "LegendForge"
    Team    = "DevOps"
  }
}

# =============================================================================
# VPC Configuration
# =============================================================================
variable "vpc_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for vpc cidr."
  type        = string
  default     = "10.0.0.0/16"
}

variable "flow_logs_retention_days" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 30
}

# =============================================================================
# Security Configuration
# =============================================================================
variable "admin_ssh_cidr" {
  description = "Optional break-glass CIDR allowed to administer LegendForge infrastructure over SSH."
  type        = string
  default     = null
}

# =============================================================================
# RDS Configuration
# =============================================================================
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

variable "postgres_version" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "15.3"
}

variable "rds_instance_class" {
  description = "RDS instance class for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 100
}

variable "rds_iops" {
  description = "RDS provisioned IOPS for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 3000
}

variable "rds_storage_throughput" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 125
}

variable "backup_retention_days" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 30
}

# =============================================================================
# EC2 Configuration
# =============================================================================
variable "ec2_instance_type" {
  description = "EC2 instance type for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "t3.medium"
}

variable "ec2_root_volume_size" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 20
}

variable "ec2_data_volume_size" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 50
}

# =============================================================================
# Auto Scaling Configuration
# =============================================================================
variable "asg_min_size" {
  description = "ASG minimum size for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG maximum size for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

# =============================================================================
# LegendForge Configuration
# =============================================================================
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

# =============================================================================
# Route53 Configuration
# =============================================================================
variable "route53_zone_id" {
  description = "Provider resource ID used by LegendForge infrastructure for route53 zone id."
  type        = string
}

variable "create_health_check" {
  description = "Whether Terraform should create health check for LegendForge infrastructure."
  type        = bool
  default     = true
}

variable "create_certificate" {
  description = "Whether Terraform should create certificate for LegendForge infrastructure."
  type        = bool
  default     = true
}

# =============================================================================
# CloudWatch Configuration
# =============================================================================
variable "cloudwatch_log_retention_days" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 30
}

# =============================================================================
# Compute Lifecycle Configuration
# =============================================================================
variable "compute_enabled" {
  description = "Whether LegendForge application compute should be created or suspended while preserving shared data."
  type        = bool
  default     = true
}
