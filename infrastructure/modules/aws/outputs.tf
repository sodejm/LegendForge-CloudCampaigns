# =============================================================================
# AWS Module Outputs
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = var.compute_enabled ? aws_instance.foundry[0].id : null
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = var.compute_enabled ? aws_instance.foundry[0].public_ip : null
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = var.compute_enabled ? aws_instance.foundry[0].private_ip : null
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = var.compute_enabled ? aws_instance.foundry[0].public_dns : null
}

output "security_group_id" {
  description = "Security group ID for the compute instance"
  value       = aws_security_group.compute.id
}

output "security_group_name" {
  description = "Security group name for the compute instance"
  value       = aws_security_group.compute.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "data_volume_id" {
  description = "EBS volume ID for persistent Foundry data"
  value       = var.compute_enabled ? aws_ebs_volume.foundry_data[0].id : null
}

output "data_volume_arn" {
  description = "EBS volume ARN"
  value       = var.compute_enabled ? aws_ebs_volume.foundry_data[0].arn : null
}

output "ec2_instance_role_name" {
  description = "IAM role name for EC2 instance"
  value       = aws_iam_role.ec2_instance_role.name
}

output "ec2_instance_role_arn" {
  description = "IAM role ARN for EC2 instance"
  value       = aws_iam_role.ec2_instance_role.arn
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "vpc_flow_logs_group" {
  description = "CloudWatch log group for VPC Flow Logs"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "instance_connect_command" {
  description = "AWS Systems Manager command to connect to the instance (requires admin_ssh_cidr if SSH is enabled)"
  value       = var.compute_enabled ? "aws ssm start-session --target ${aws_instance.foundry[0].id} --region ${local.region}" : null
}

output "foundry_instance_summary" {
  description = "Summary of Foundry instance details"
  value = var.compute_enabled ? {
    instance_id      = aws_instance.foundry[0].id
    public_ip        = aws_instance.foundry[0].public_ip
    region           = local.region
    availability_zone = aws_instance.foundry[0].availability_zone
    vpc_id           = aws_vpc.main.id
    security_group   = aws_security_group.compute.name
    data_volume      = aws_ebs_volume.foundry_data[0].id
  } : null
}
