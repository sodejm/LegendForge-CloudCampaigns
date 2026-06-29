# =============================================================================
# infrastructure/deployments/aws/main.tf
# =============================================================================
# LegendForge AWS deployment configuration for universal tabletop infrastructure with multi-system support.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# BUILT ON:
# - Foundry VTT: https://github.com/foundryvtt
# - felddy/foundryvtt Docker: https://github.com/felddy/foundryvtt-docker
# - Cloudflare Tunnel: https://www.cloudflare.com/products/tunnel/
# - Terraform: https://www.terraform.io/
# - AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/
#
# This configuration leverages excellent open-source and community projects.
# See ATTRIBUTION.md for full credits.
# =============================================================================

# =============================================================================
# AWS Provider
# =============================================================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# =============================================================================
# Local Values
# =============================================================================
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "LegendForge"
    }
  )

  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)
}

# =============================================================================
# Data Sources
# =============================================================================
data "aws_availability_zones" "available" {
  state = "available"
}

# =============================================================================
# Module: VPC for LegendForge multi-system operations.
# =============================================================================
module "vpc" {
  source = "../../modules/aws-vpc"

  environment              = var.environment
  aws_region               = var.aws_region
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = local.azs
  flow_logs_retention_days = var.flow_logs_retention_days
  tags                     = local.common_tags
}

# =============================================================================
# Module: Security Groups for LegendForge multi-system operations.
# =============================================================================
module "security_groups" {
  source = "../../modules/aws-security-groups"

  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  admin_ssh_cidr = var.admin_ssh_cidr
  tags           = local.common_tags
}

# =============================================================================
# Module: RDS (Database) for LegendForge multi-system operations.
# =============================================================================
module "rds" {
  source = "../../modules/aws-rds"

  environment           = var.environment
  database_name         = var.database_name
  database_username     = var.database_username
  database_password     = var.database_password
  database_subnet_ids   = module.vpc.database_subnet_ids
  rds_security_group_id = module.security_groups.rds_security_group_id
  postgres_version      = var.postgres_version
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  iops                  = var.rds_iops
  storage_throughput    = var.rds_storage_throughput
  backup_retention_days = var.backup_retention_days
  tags                  = local.common_tags

  depends_on = [module.vpc]
}

# =============================================================================
# Module: S3 for LegendForge multi-system operations.
# =============================================================================
module "s3" {
  source = "../../modules/aws-s3"

  environment                = var.environment
  cloudfront_distribution_id = try(module.cloudfront.distribution_id, "")
  tags                       = local.common_tags

  depends_on = [module.vpc]
}

# =============================================================================
# Module: IAM for LegendForge multi-system operations.
# =============================================================================
module "iam" {
  source = "../../modules/aws-iam"

  environment                  = var.environment
  aws_region                   = var.aws_region
  foundry_data_bucket_arn      = module.s3.foundry_data_bucket_arn
  cloudfront_assets_bucket_arn = module.s3.cloudfront_assets_bucket_arn
  tags                         = local.common_tags
}

# =============================================================================
# Module: ALB (Load Balancer) for LegendForge multi-system operations.
# =============================================================================
module "alb" {
  source = "../../modules/aws-alb"

  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  certificate_arn       = module.route53.certificate_arn
  tags                  = local.common_tags

  depends_on = [module.vpc, module.security_groups]
}

# =============================================================================
# Module: CloudFront for LegendForge multi-system operations.
# =============================================================================
module "cloudfront" {
  source = "../../modules/aws-cloudfront"

  environment               = var.environment
  assets_bucket_domain_name = module.s3.cloudfront_assets_bucket_name
  alb_domain_name           = module.alb.alb_dns_name
  use_default_certificate   = true
  create_invalidation       = false
  tags                      = local.common_tags

}

# =============================================================================
# Module: Auto Scaling Group & EC2 for LegendForge multi-system operations.
# =============================================================================
module "asg_ec2" {
  source = "../../modules/aws-asg-ec2"

  environment             = var.environment
  aws_region              = var.aws_region
  private_subnet_ids      = module.vpc.private_subnet_ids
  asg_security_group_id   = module.security_groups.asg_security_group_id
  instance_profile_arn    = module.iam.instance_profile_arn
  target_group_arn        = module.alb.target_group_arn
  instance_type           = var.ec2_instance_type
  root_volume_size        = var.ec2_root_volume_size
  data_volume_size        = var.ec2_data_volume_size
  min_size                = var.asg_min_size
  max_size                = var.asg_max_size
  desired_capacity        = var.asg_desired_capacity
  foundry_hostname        = var.foundry_hostname
  foundry_image           = var.foundry_image
  cloudflared_image       = var.cloudflared_image
  cloudflare_tunnel_token = var.cloudflare_tunnel_token
  foundry_license_key     = var.foundry_license_key
  foundry_admin_key       = var.foundry_admin_key
  db_host                 = module.rds.rds_address
  db_port                 = module.rds.rds_port
  db_name                 = var.database_name
  db_username             = var.database_username
  db_password             = var.database_password
  foundry_data_bucket     = module.s3.foundry_data_bucket_name
  cloudwatch_log_group    = module.cloudwatch.foundry_log_group
  tags                    = local.common_tags

  depends_on = [module.rds, module.iam, module.alb, module.s3]
}

# =============================================================================
# Module: CloudWatch Monitoring for LegendForge multi-system operations.
# =============================================================================
module "cloudwatch" {
  source = "../../modules/aws-cloudwatch"

  environment        = var.environment
  aws_region         = var.aws_region
  log_retention_days = var.cloudwatch_log_retention_days
  rds_instance_id    = module.rds.rds_arn
  tags               = local.common_tags
}

# =============================================================================
# Module: Route53 & DNS for LegendForge multi-system operations.
# =============================================================================
module "route53" {
  source = "../../modules/aws-route53"

  environment         = var.environment
  zone_id             = var.route53_zone_id
  foundry_hostname    = var.foundry_hostname
  alb_dns_name        = module.alb.alb_dns_name
  alb_zone_id         = module.alb.alb_zone_id
  create_health_check = var.create_health_check
  create_certificate  = var.create_certificate
  tags                = local.common_tags

}

# =============================================================================
# Outputs
# =============================================================================
output "foundry_url" {
  description = "LegendForge URL with multi-system support."
  value       = "https://${module.route53.dns_record_fqdn}"
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = module.cloudfront.distribution_domain_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "s3_data_bucket" {
  description = "S3 LegendForge data bucket with multi-system support."
  value       = module.s3.foundry_data_bucket_name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.cloudwatch.dashboard_url
}
