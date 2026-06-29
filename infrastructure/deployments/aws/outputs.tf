# =============================================================================
# AWS Deployment Outputs — Summary and Important Information
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.asg_ec2.asg_name
}

output "asg_security_group_id" {
  description = "Security group ID for the Auto Scaling Group instances"
  value       = module.security_groups.asg_security_group_id
}

# ===== Next Steps =====
output "next_steps" {
  description = "Next steps for completing the deployment"
  value       = <<-EOT
    1. Access LegendForge at the configured hostname (see foundry_url output).

    2. To spin down (keep data):
       terraform apply -var="compute_enabled=false"

    3. To spin up again:
       terraform apply -var="compute_enabled=true"
  EOT
}
