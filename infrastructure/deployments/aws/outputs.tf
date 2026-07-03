# =============================================================================
# AWS Deployment Outputs — Summary and Important Information
# =============================================================================

output "asg_name" {
  description = "Auto Scaling Group name for Foundry instances"
  value       = module.asg_ec2.asg_name
}

output "alb_dns" {
  description = "ALB DNS name (entry point for the Foundry application)"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "security_group_id" {
  description = "Security group ID for Foundry ASG instances"
  value       = module.security_groups.asg_security_group_id
}

output "connect_command" {
  description = "AWS Systems Manager command to connect to a running Foundry instance"
  value       = "aws ssm start-session --target $(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${module.asg_ec2.asg_name} --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text) --region ${var.aws_region}"
}

output "foundry_summary" {
  description = "Summary of Foundry deployment on AWS"
  value       = "Foundry deployed to ${var.environment} — ASG: ${module.asg_ec2.asg_name}, URL: https://${var.foundry_hostname}"
}

# ===== Next Steps =====
output "next_steps" {
  description = "Next steps for completing the deployment"
  value = var.compute_enabled ? (
    <<-EOT
      1. Verify the Auto Scaling Group is running:
         aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${module.asg_ec2.asg_name} --region ${var.aws_region}

      2. Connect to an instance using Systems Manager:
         aws ssm start-session --target $(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${module.asg_ec2.asg_name} --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text) --region ${var.aws_region}

      3. Monitor Docker container startup:
         docker ps
         docker logs -f foundry

      4. Access Foundry once the Cloudflare Tunnel is connected:
         https://${var.foundry_hostname}

      5. Configure Foundry at:
         https://${var.foundry_hostname}/setup (requires foundry_admin_key)

      6. To spin down (keep data):
         terraform apply -var="compute_enabled=false"

      7. To spin up again:
         terraform apply -var="compute_enabled=true"
    EOT
  ) : "Instance is disabled (compute_enabled=false). Run: terraform apply -var='compute_enabled=true'"
}
