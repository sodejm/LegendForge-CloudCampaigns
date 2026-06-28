output "foundry_data_bucket_name" {
  description = "Foundry data bucket name"
  value       = aws_s3_bucket.foundry_data.id
}

output "foundry_data_bucket_arn" {
  description = "Foundry data bucket ARN"
  value       = aws_s3_bucket.foundry_data.arn
}

output "cloudfront_assets_bucket_name" {
  description = "CloudFront assets bucket name"
  value       = aws_s3_bucket.cloudfront_assets.id
}

output "cloudfront_assets_bucket_arn" {
  description = "CloudFront assets bucket ARN"
  value       = aws_s3_bucket.cloudfront_assets.arn
}

output "logs_bucket_name" {
  description = "Logs bucket name"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "Logs bucket ARN"
  value       = aws_s3_bucket.logs.arn
}
