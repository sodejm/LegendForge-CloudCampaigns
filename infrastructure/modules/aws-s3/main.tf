# =============================================================================
# infrastructure/modules/aws-s3/main.tf
# =============================================================================
# LegendForge AWS S3 module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# =============================================================================
# Main Foundry Data Bucket
# =============================================================================
resource "aws_s3_bucket" "foundry_data" {
  bucket = "${var.environment}-foundry-data-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-foundry-data"
    }
  )
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "foundry_data" {
  bucket = aws_s3_bucket.foundry_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning for data protection
resource "aws_s3_bucket_versioning" "foundry_data" {
  bucket = aws_s3_bucket.foundry_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "foundry_data" {
  bucket = aws_s3_bucket.foundry_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable logging
resource "aws_s3_bucket_logging" "foundry_data" {
  bucket = aws_s3_bucket.foundry_data.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "foundry-data/"
}

# Lifecycle policy: transition old versions and delete after retention
resource "aws_s3_bucket_lifecycle_configuration" "foundry_data" {
  bucket = aws_s3_bucket.foundry_data.id

  rule {
    id     = "foundry-data-lifecycle"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
  }
}

# =============================================================================
# CloudFront Assets Bucket (for static content distribution)
# =============================================================================
resource "aws_s3_bucket" "cloudfront_assets" {
  bucket = "${var.environment}-foundry-assets-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-foundry-assets"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "cloudfront_assets" {
  bucket = aws_s3_bucket.cloudfront_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudfront_assets" {
  bucket = aws_s3_bucket.cloudfront_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_assets" {
  bucket = aws_s3_bucket.cloudfront_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# =============================================================================
# Logging Bucket
# =============================================================================
resource "aws_s3_bucket" "logs" {
  bucket = "${var.environment}-foundry-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-foundry-logs"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logs-lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# =============================================================================
# S3 Bucket Policies
# =============================================================================

# Deny unencrypted uploads
resource "aws_s3_bucket_policy" "foundry_data" {
  bucket = aws_s3_bucket.foundry_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.foundry_data.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid       = "DenyUnencryptedTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.foundry_data.arn,
          "${aws_s3_bucket.foundry_data.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "cloudfront_assets" {
  bucket = aws_s3_bucket.cloudfront_assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.cloudfront_assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"
          }
        }
      },
      {
        Sid       = "DenyUnencryptedTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.cloudfront_assets.arn,
          "${aws_s3_bucket.cloudfront_assets.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# =============================================================================
# Data Source
# =============================================================================
data "aws_caller_identity" "current" {}
