output "ec2_role_name" {
  description = "IAM role name for EC2 instances"
  value       = aws_iam_role.ec2_foundry.name
}

output "ec2_role_arn" {
  description = "IAM role ARN for EC2 instances"
  value       = aws_iam_role.ec2_foundry.arn
}

output "instance_profile_arn" {
  description = "Instance profile ARN"
  value       = aws_iam_instance_profile.ec2_foundry.arn
}

output "instance_profile_name" {
  description = "Instance profile name"
  value       = aws_iam_instance_profile.ec2_foundry.name
}
