# =============================================================================
# infrastructure/modules/aws-route53/main.tf
# =============================================================================
# LegendForge AWS Route53 module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.

# =============================================================================
# DNS Record for ALB
# =============================================================================
resource "aws_route53_record" "alb" {
  zone_id = var.zone_id
  name    = var.foundry_hostname
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# =============================================================================
# Health Check for ALB
# =============================================================================
resource "aws_route53_health_check" "alb" {
  count             = var.create_health_check ? 1 : 0
  type              = "HTTPS"
  resource_path     = "/api/health"
  fqdn              = aws_route53_record.alb.name
  port              = 443
  failure_threshold = 3
  request_interval  = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-alb-health-check"
    }
  )
}

# =============================================================================
# ACM Certificate (if needed - usually managed separately)
# =============================================================================
resource "aws_acm_certificate" "foundry" {
  count             = var.create_certificate ? 1 : 0
  domain_name       = var.foundry_hostname
  validation_method = "DNS"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-foundry-cert"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for ACM certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in try(aws_acm_certificate.foundry[0].domain_validation_options, []) :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "foundry" {
  count           = var.create_certificate ? 1 : 0
  certificate_arn = aws_acm_certificate.foundry[0].arn

  timeouts {
    create = "5m"
  }

  depends_on = [aws_route53_record.cert_validation]
}

# =============================================================================
# CloudWatch Alarm for Health Check
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count               = var.create_health_check ? 1 : 0
  alarm_name          = "${var.environment}-foundry-health-check-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alert when health check fails"

  dimensions = {
    HealthCheckId = aws_route53_health_check.alb[0].id
  }
}
