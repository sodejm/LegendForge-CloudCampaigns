# =============================================================================
# infrastructure/deployments/gcp/main.tf
# =============================================================================
# LegendForge GCP deployment configuration for universal tabletop infrastructure with multi-system support.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# BUILT ON:
# - Foundry VTT: https://github.com/foundryvtt
# - felddy/foundryvtt Docker: https://github.com/felddy/foundryvtt-docker
# - Cloudflare Tunnel: https://www.cloudflare.com/products/tunnel/
# - Terraform: https://www.terraform.io/
# - GCP Provider: https://registry.terraform.io/providers/hashicorp/google/
#
# This configuration leverages excellent open-source and community projects.
# See ATTRIBUTION.md for full credits.
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.39"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.39"
    }
  }

  # Uncomment to use remote state
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "legendforge/gcp"
  # }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.primary_region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.primary_region
}

# =============================================================================
# VPC & Networking
# =============================================================================

module "vpc" {
  source = "../../modules/gcp-vpc"

  project_name            = var.project_name
  primary_region          = var.primary_region
  secondary_region        = var.secondary_region
  primary_subnet_cidr     = var.primary_subnet_cidr
  secondary_subnet_cidr   = var.secondary_subnet_cidr
  enable_secondary_subnet = var.enable_multi_region
  admin_source_ranges     = var.admin_source_ranges
}

# =============================================================================
# IAM & Service Accounts
# =============================================================================

module "iam" {
  source = "../../modules/gcp-iam"

  gcp_project_id = var.gcp_project_id
  project_name   = var.project_name
}

# =============================================================================
# Secret Management
# =============================================================================

module "secrets" {
  source = "../../modules/gcp-secrets"

  project_name             = var.project_name
  region                   = var.primary_region
  gcp_project_number       = data.google_project.current.number
  foundry_compute_sa_email = module.iam.foundry_compute_sa_email
  database_password        = var.database_password
  foundry_license_key      = var.foundry_license_key
  foundry_admin_key        = var.foundry_admin_key
  foundry_username         = var.foundry_username
  foundry_password         = var.foundry_password
  cloudflare_tunnel_token  = var.cloudflare_tunnel_token
}

# =============================================================================
# Cloud SQL Database
# =============================================================================

module "cloudsql" {
  source = "../../modules/gcp-cloudsql"

  project_name             = var.project_name
  primary_region           = var.primary_region
  replica_region           = var.secondary_region
  database_version         = var.database_version
  machine_type             = var.cloudsql_machine_type
  foundry_database_name    = var.foundry_database_name
  foundry_db_user          = var.foundry_db_user
  foundry_backup_user      = var.foundry_backup_user
  vpc_network_id           = module.vpc.vpc_id
  primary_subnet_cidr      = var.primary_subnet_cidr
  enable_public_ip         = var.enable_cloudsql_public_ip
  enable_read_replica      = var.enable_multi_region
  enable_automated_backups = true
  deletion_protection      = var.enable_deletion_protection

  labels = var.labels
}

# =============================================================================
# Cloud Storage
# =============================================================================

module "storage" {
  source = "../../modules/gcp-storage"

  project_name             = var.project_name
  primary_region           = var.primary_region
  backup_location          = var.backup_location
  kms_key_id               = module.secrets.kms_key_id
  foundry_compute_sa_email = module.iam.foundry_compute_sa_email

  labels = var.labels
}

# =============================================================================
# Compute Engine
# =============================================================================

module "compute" {
  source = "../../modules/gcp-compute"

  project_name              = var.project_name
  primary_region            = var.primary_region
  machine_type              = var.compute_machine_type
  boot_disk_image           = var.boot_disk_image
  data_disk_size_gb         = var.data_disk_size_gb
  min_instances             = var.min_instances
  max_instances             = var.max_instances
  cpu_target_utilization    = var.cpu_target_utilization
  enable_memory_autoscaling = var.enable_memory_autoscaling
  foundry_compute_sa_email  = module.iam.foundry_compute_sa_email
  vpc_network_name          = module.vpc.vpc_name
  subnet_name               = module.vpc.primary_subnet_name
  kms_key_id                = module.secrets.kms_key_id
  startup_script = templatefile("${path.module}/templates/cloud-init.yaml", {
    project_name           = var.project_name
    foundry_license_key    = "projects/${var.gcp_project_id}/secrets/${var.project_name}-foundry-license-key/versions/latest"
    foundry_admin_key      = "projects/${var.gcp_project_id}/secrets/${var.project_name}-foundry-admin-key/versions/latest"
    foundry_username       = "projects/${var.gcp_project_id}/secrets/${var.project_name}-foundry-username/versions/latest"
    foundry_password       = "projects/${var.gcp_project_id}/secrets/${var.project_name}-foundry-password/versions/latest"
    cloudflare_token       = "projects/${var.gcp_project_id}/secrets/${var.project_name}-cloudflare-tunnel-token/versions/latest"
    database_host          = module.cloudsql.database_private_ip
    database_port          = "5432"
    database_name          = module.cloudsql.database_name
    database_user          = module.cloudsql.database_user
    database_password      = "projects/${var.gcp_project_id}/secrets/${var.project_name}-db-password/versions/latest"
    foundry_data_bucket    = module.storage.foundry_data_bucket
    foundry_media_bucket   = module.storage.foundry_media_bucket
    foundry_backups_bucket = module.storage.foundry_backups_bucket
    foundry_hostname       = var.foundry_hostname
  })

  labels = var.labels

  depends_on = [
    module.vpc,
    module.iam,
    module.cloudsql,
    module.storage,
    module.secrets
  ]
}

# =============================================================================
# Load Balancer
# =============================================================================

module "loadbalancer" {
  source = "../../modules/gcp-loadbalancer"

  project_name               = var.project_name
  domain_name                = var.domain_name
  instance_group_id          = module.compute.instance_group_id
  health_check_id            = module.compute.health_check_id
  enable_cdn                 = var.enable_cdn
  enable_adaptive_protection = var.enable_cloud_armor

  depends_on = [module.compute]
}

# =============================================================================
# Monitoring & Alerting
# =============================================================================

module "monitoring" {
  source = "../../modules/gcp-monitoring"

  instance_group_name      = module.compute.instance_group_name
  domain_name              = var.domain_name
  gcp_project_id           = var.gcp_project_id
  database_instance_name   = module.cloudsql.database_instance_name
  notification_channel_ids = var.notification_channel_ids

  depends_on = [module.compute, module.cloudsql]
}

# =============================================================================
# Data sources
# =============================================================================

data "google_client_config" "current" {}
data "google_project" "current" {}

data "google_project" "current" {
  project_id = data.google_client_config.current.project
}

# =============================================================================
# Outputs
# =============================================================================

output "load_balancer_ip" {
  description = "Load balancer static IP address"
  value       = module.loadbalancer.load_balancer_ip
}

output "vpc_id" {
  description = "VPC network ID"
  value       = module.vpc.vpc_id
}

output "database_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.cloudsql.database_connection_name
}

output "database_private_ip" {
  description = "Cloud SQL private IP"
  value       = module.cloudsql.database_private_ip
}

output "instance_group_id" {
  description = "Compute Engine instance group ID"
  value       = module.compute.instance_group_id
}

output "foundry_data_bucket" {
  description = "Cloud Storage data bucket"
  value       = module.storage.foundry_data_bucket
}

output "foundry_backups_bucket" {
  description = "Cloud Storage backups bucket"
  value       = module.storage.foundry_backups_bucket
}

output "monitoring_dashboard_id" {
  description = "Monitoring dashboard ID"
  value       = module.monitoring.dashboard_id
}

output "deployment_complete" {
  description = "Deployment status"
  value       = "✓ D&D Foundry VTT infrastructure deployed successfully on GCP"
}
