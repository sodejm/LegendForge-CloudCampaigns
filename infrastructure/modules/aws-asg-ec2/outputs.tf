output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.foundry.name
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.foundry.id
}

output "launch_template_latest_version" {
  description = "Latest launch template version"
  value       = aws_launch_template.foundry.latest_version
}
