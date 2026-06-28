# =============================================================================
# infrastructure/modules/aws-cloudwatch/main.tf
# =============================================================================
# LegendForge AWS Cloudwatch module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# =============================================================================
# Log Groups
# =============================================================================
resource "aws_cloudwatch_log_group" "foundry_application" {
  name              = "/foundry/${var.environment}/application"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-foundry-application-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "foundry_docker" {
  name              = "/foundry/${var.environment}/docker"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-foundry-docker-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/rds/${var.environment}/postgresql"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-rds-logs"
    }
  )
}

# =============================================================================
# CloudWatch Dashboard
# =============================================================================
resource "aws_cloudwatch_dashboard" "foundry" {
  dashboard_name = "${var.environment}-foundry"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            [".", "RequestCount", { stat = "Sum" }],
            [".", "HTTPCode_Target_2XX_Count", { stat = "Sum" }],
            [".", "HTTPCode_Target_4XX_Count", { stat = "Sum" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            [".", "NetworkIn", { stat = "Sum" }],
            [".", "NetworkOut", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Instance Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }],
            [".", "DatabaseConnections", { stat = "Average" }],
            [".", "ReadLatency", { stat = "Average" }],
            [".", "WriteLatency", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query  = "fields @timestamp, @message | stats count() by bin(5m)"
          region = var.aws_region
          title  = "Application Log Events"
        }
      }
    ]
  })
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================

# RDS Alarms
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when RDS CPU utilization is high"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory" {
  alarm_name          = "${var.environment}-rds-low-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "268435456" # 256 MB
  alarm_description   = "Alert when RDS available memory is low"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_disk_space" {
  alarm_name          = "${var.environment}-rds-low-disk"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2147483648" # 2 GB
  alarm_description   = "Alert when RDS free storage is low"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.environment}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "150"
  alarm_description   = "Alert when RDS connections are high"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

# Application Alarms
resource "aws_cloudwatch_metric_alarm" "app_disk_space" {
  alarm_name          = "${var.environment}-foundry-disk-space-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DISK_USED_PERCENT"
  namespace           = "Foundry"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Alert when disk usage exceeds 85%"
}

resource "aws_cloudwatch_metric_alarm" "app_memory_high" {
  alarm_name          = "${var.environment}-foundry-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MEM_USED_PERCENT"
  namespace           = "Foundry"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Alert when memory usage exceeds 85%"
}

# =============================================================================
# Metric Filters for Log-based Alarms
# =============================================================================
resource "aws_cloudwatch_log_group_metric_filter" "error_logs" {
  name           = "${var.environment}-error-logs"
  log_group_name = aws_cloudwatch_log_group.foundry_application.name
  filter_pattern = "[ERROR]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "Foundry"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_count_high" {
  alarm_name          = "${var.environment}-foundry-errors-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ErrorCount"
  namespace           = "Foundry"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "Alert when error count exceeds 50 in 5 minutes"
}
