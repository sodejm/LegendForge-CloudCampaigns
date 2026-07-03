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

output "security_group_id" {
  description = "Security group ID for Foundry ASG instances"
  value       = module.security_groups.asg_security_group_id
}

# ===== Next Steps =====
output "next_steps" {
  description = "Next steps for completing the deployment"
  sensitive   = true
  value = var.compute_enabled ? (
    <<-EOT
      1. Verify the Foundry Auto Scaling Group is running:
         aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${module.asg_ec2.asg_name} --region ${var.aws_region}

      2. Monitor Docker container startup on an instance via SSM:
         docker ps
         docker logs -f foundry

      3. Access Foundry once the Cloudflare Tunnel is connected:
         https://${var.foundry_hostname}

      4. Configure Foundry at:
         https://${var.foundry_hostname}/setup (requires foundry_admin_key)

      5. To spin down (keep data):
         terraform apply -var="compute_enabled=false"

      6. To spin up again:
         terraform apply -var="compute_enabled=true"
    EOT
  ) : "Instance is disabled (compute_enabled=false). Run: terraform apply -var='compute_enabled=true'"
}
