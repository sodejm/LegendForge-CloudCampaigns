# =============================================================================
# AWS Locals — Common values and naming conventions
# =============================================================================

locals {
  project = var.project_name
  env     = var.environment
  region  = var.aws_region

  # Naming convention for all resources
  name_prefix = "${local.project}-${local.env}"

  # Common tags applied to all resources
  common_tags = {
    Project     = local.project
    Environment = local.env
    ManagedBy   = "Terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }

  # Networking defaults
  vpc_cidr             = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # Compute defaults
  instance_type    = var.instance_type
  root_volume_size = 30
  root_volume_type = "gp3"
}

# Data source: available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source: latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
