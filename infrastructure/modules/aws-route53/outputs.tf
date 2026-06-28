output "dns_record_name" {
  description = "DNS record name"
  value       = aws_route53_record.alb.name
}

output "dns_record_fqdn" {
  description = "DNS record FQDN"
  value       = aws_route53_record.alb.fqdn
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = try(aws_acm_certificate.foundry[0].arn, "")
}

output "certificate_domain_validation_options" {
  description = "Domain validation options for certificate"
  value       = try(aws_acm_certificate.foundry[0].domain_validation_options, [])
  sensitive   = true
}

output "health_check_id" {
  description = "Route53 health check ID"
  value       = try(aws_route53_health_check.alb[0].id, "")
}
