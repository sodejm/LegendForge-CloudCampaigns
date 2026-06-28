output "foundry_log_group" {
  description = "Foundry application log group name"
  value       = aws_cloudwatch_log_group.foundry_application.name
}

output "docker_log_group" {
  description = "Docker log group name"
  value       = aws_cloudwatch_log_group.foundry_docker.name
}

output "rds_log_group" {
  description = "RDS log group name"
  value       = aws_cloudwatch_log_group.rds.name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.foundry.dashboard_name}"
}
