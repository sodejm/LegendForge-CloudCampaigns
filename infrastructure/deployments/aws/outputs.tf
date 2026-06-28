# =============================================================================
# AWS Deployment Outputs — Summary and Important Information
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.foundry_aws.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.foundry_aws.instance_public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.foundry_aws.instance_public_dns
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.foundry_aws.vpc_id
}

output "security_group_id" {
  description = "Security group ID for Foundry instance"
  value       = module.foundry_aws.security_group_id
}

output "data_volume_id" {
  description = "EBS volume ID for Foundry persistent data"
  value       = module.foundry_aws.data_volume_id
}

output "connect_command" {
  description = "AWS Systems Manager command to connect to the instance"
  value       = module.foundry_aws.instance_connect_command
}

output "foundry_summary" {
  description = "Summary of Foundry deployment on AWS"
  value       = module.foundry_aws.foundry_instance_summary
}

# ===== Next Steps =====
output "next_steps" {
  description = "Next steps for completing the deployment"
  value = var.compute_enabled ? (
    <<-EOT
      1. Verify the Foundry instance is running:
         aws ec2 describe-instances --instance-ids ${module.foundry_aws.instance_id} --region ${var.aws_region}

      2. Connect to the instance using Systems Manager:
         ${module.foundry_aws.instance_connect_command}

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
