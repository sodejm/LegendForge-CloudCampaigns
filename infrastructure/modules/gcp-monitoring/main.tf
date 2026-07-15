# =============================================================================
# infrastructure/modules/gcp-monitoring/main.tf
# =============================================================================
# LegendForge GCP Monitoring module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# --- Monitoring Dashboard ---
resource "google_monitoring_dashboard" "foundry" {
  dashboard_json = jsonencode({
    displayName = "D&D Foundry VTT Production"
    mosaicLayout = {
      columns = 12
      tiles = [
        # Compute Engine metrics
        {
          width  = 6
          height = 4
          widget = {
            title = "CPU Utilization"
            xyChart = {
              chartOptions = {
                mode = "COLOR"
              }
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND resource.label.instance_group_manager_name=\"${var.instance_group_name}\""
                    }
                  }
                  plotType = "LINE"
                }
              ]
              timeshiftDuration = "0s"
              yAxis = {
                label = "CPU Utilization"
                scale = "LINEAR"
              }
            }
          }
        },
        # Memory metrics
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Memory Utilization"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"compute.googleapis.com/instance/memory/utilization\" AND resource.type=\"gce_instance\" AND resource.label.instance_group_manager_name=\"${var.instance_group_name}\""
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        # Network metrics
        {
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Network In/Out"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"compute.googleapis.com/instance/network/received_bytes_count\" AND resource.type=\"gce_instance\" AND resource.label.instance_group_manager_name=\"${var.instance_group_name}\""
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        # Load Balancer health
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Backend Health"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"loadbalancing.googleapis.com/https/internal/request_count\" AND resource.type=\"https_lb_rule\""
                    }
                  }
                  plotType = "STACKED_AREA"
                }
              ]
            }
          }
        },
        # Cloud SQL metrics
        {
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Cloud SQL CPU"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\" AND resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.gcp_project_id}:${var.database_instance_name}\""
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        # Cloud SQL connections
        {
          xPos   = 6
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Cloud SQL Connections"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"cloudsql.googleapis.com/database/network/connections\" AND resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.gcp_project_id}:${var.database_instance_name}\""
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
      ]
    }
  })
}

# --- Alerting Policy: High CPU ---
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "Foundry - High CPU Utilization"
  combiner     = "OR"

  conditions {
    display_name = "CPU > 80%"

    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND resource.label.instance_group_manager_name=\"${var.instance_group_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channel_ids

  alert_strategy {
    auto_close = "1800s"
  }
}

# --- Alerting Policy: High Memory ---
resource "google_monitoring_alert_policy" "high_memory" {
  display_name = "Foundry - High Memory Utilization"
  combiner     = "OR"

  conditions {
    display_name = "Memory > 85%"

    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/memory/utilization\" AND resource.type=\"gce_instance\" AND resource.label.instance_group_manager_name=\"${var.instance_group_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channel_ids
}

# --- Alerting Policy: Backend unhealthy ---
resource "google_monitoring_alert_policy" "backend_unhealthy" {
  display_name = "Foundry - Backend Unhealthy"
  combiner     = "OR"

  conditions {
    display_name = "Backend instance unhealthy"

    condition_threshold {
      filter          = "metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\" AND resource.type=\"https_lb_rule\""
      duration        = "60s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.notification_channel_ids
}

# --- Alerting Policy: Cloud SQL CPU ---
resource "google_monitoring_alert_policy" "cloudsql_cpu" {
  display_name = "Foundry - Cloud SQL High CPU"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL CPU > 75%"

    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\" AND resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.gcp_project_id}:${var.database_instance_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.75

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channel_ids
}

# --- Uptime Check (external) ---
resource "google_monitoring_uptime_check_config" "foundry" {
  display_name = "Foundry VTT HTTPS Uptime"
  timeout      = "10s"
  period       = "60s"

  http_check {
    port           = 443
    use_ssl        = true
    path           = "/"
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      host = var.domain_name
    }
  }

  selected_regions = ["USA", "EUROPE", "ASIA_PACIFIC"]
}

# --- Alert for uptime check failures ---
resource "google_monitoring_alert_policy" "uptime_failure" {
  display_name = "Foundry - Uptime Check Failed"
  combiner     = "OR"

  conditions {
    display_name = "Uptime check failed"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND resource.label.host=\"${var.domain_name}\""
      duration        = "60s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }

  notification_channels = var.notification_channel_ids
}

# --- Log-based metric for LegendForge errors ---
resource "google_logging_metric" "foundry_errors" {
  name   = "foundry_application_errors"
  filter = "resource.type=\"gce_instance\" AND resource.label.instance_group_manager_name=\"${var.instance_group_name}\" AND (jsonPayload.level=\"ERROR\" OR severity=\"ERROR\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# --- Alert on error spike ---
resource "google_monitoring_alert_policy" "error_spike" {
  display_name = "Foundry - Error Spike Detected"
  combiner     = "OR"

  conditions {
    display_name = "Error rate spike"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/foundry_application_errors\" AND resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.notification_channel_ids
}
