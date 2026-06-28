# =============================================================================
# infrastructure/modules/aws-cloudfront/main.tf
# =============================================================================
# LegendForge AWS Cloudfront module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# =============================================================================
# Origin Access Control (OAC) for S3
# =============================================================================
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.environment}-foundry-oac"
  description                       = "OAC for LegendForge assets S3 bucket with multi-system support."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# =============================================================================
# CloudFront Distribution
# =============================================================================
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""
  http_version        = "http2and3"

  origin {
    domain_name              = var.assets_bucket_domain_name
    origin_id                = "S3-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id

    custom_header {
      name  = "User-Agent"
      value = "CloudFront"
    }
  }

  # ALB origin for LegendForge application
  origin {
    domain_name = var.alb_domain_name
    origin_id   = "ALB-Foundry"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default behavior for LegendForge app
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-Foundry"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  # Cache behavior for static assets
  cache_behavior {
    path_pattern     = "/assets/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-assets"

    forwarded_values {
      query_string = false
      headers      = ["Accept"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  # Cache behavior for maps and modules
  cache_behavior {
    path_pattern     = "/maps/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-assets"

    forwarded_values {
      query_string = false
      headers      = ["Accept"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.use_default_certificate
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.use_default_certificate ? null : "sni-only"
    minimum_protocol_version       = var.use_default_certificate ? null : "TLSv1.2_2021"
  }

  # Custom headers for security
  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 0
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-foundry-cdn"
    }
  )
}

# =============================================================================
# CloudFront Functions for security headers
# =============================================================================
resource "aws_cloudfront_function" "security_headers" {
  name    = "${var.environment}-security-headers"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = <<-EOT
    function handler(event) {
      var response = event.response;
      var headers = response.headers;

      headers['strict-transport-security'] = {
        value: 'max-age=63072000; includeSubdomains; preload'
      };

      headers['x-content-type-options'] = {
        value: 'nosniff'
      };

      headers['x-frame-options'] = {
        value: 'SAMEORIGIN'
      };

      headers['x-xss-protection'] = {
        value: '1; mode=block'
      };

      headers['referrer-policy'] = {
        value: 'strict-origin-when-cross-origin'
      };

      return response;
    }
  EOT
}

# Associate security headers function with distribution
resource "aws_cloudfront_distribution_function_association" "security_headers" {
  distribution_id = aws_cloudfront_distribution.main.id
  event_type      = "viewer-response"
  function_arn    = aws_cloudfront_function.security_headers.arn
}

# =============================================================================
# CloudFront Invalidation (optional - managed externally)
# =============================================================================
resource "aws_cloudfront_invalidation" "main" {
  count           = var.create_invalidation ? 1 : 0
  distribution_id = aws_cloudfront_distribution.main.id
  paths           = ["/*"]

  triggers = {
    deployment = var.invalidation_trigger
  }
}
