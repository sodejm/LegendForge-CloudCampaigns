output "dashboard_id" {
  description = "Monitoring dashboard ID"
  value       = google_monitoring_dashboard.foundry.id
}

output "alert_policy_high_cpu_id" {
  description = "High CPU alert policy ID"
  value       = google_monitoring_alert_policy.high_cpu.id
}

output "alert_policy_high_memory_id" {
  description = "High memory alert policy ID"
  value       = google_monitoring_alert_policy.high_memory.id
}

output "alert_policy_uptime_id" {
  description = "Uptime check alert policy ID"
  value       = google_monitoring_alert_policy.uptime_failure.id
}

output "uptime_check_id" {
  description = "Uptime check ID"
  value       = google_monitoring_uptime_check_config.foundry.id
}

output "log_metric_id" {
  description = "Log-based metric for error tracking"
  value       = google_logging_metric.foundry_errors.id
}
