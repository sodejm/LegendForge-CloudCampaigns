# =============================================================================
# infrastructure/modules/aws-iam/main.tf
# =============================================================================
# LegendForge AWS Iam module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# =============================================================================
# EC2 Instance Role
# =============================================================================
resource "aws_iam_role" "ec2_foundry" {
  name = "${var.environment}-foundry-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_instance_profile" "ec2_foundry" {
  name = "${var.environment}-foundry-instance-profile"
  role = aws_iam_role.ec2_foundry.name
}

# =============================================================================
# S3 Access Policy (read/write to LegendForge platform data and assets)
# =============================================================================
resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "${var.environment}-foundry-s3-policy"
  role = aws_iam_role.ec2_foundry.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListS3Buckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = [
          var.foundry_data_bucket_arn,
          var.cloudfront_assets_bucket_arn
        ]
      },
      {
        Sid    = "FoundryDataBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = "${var.foundry_data_bucket_arn}/*"
      },
      {
        Sid    = "AssetsBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.cloudfront_assets_bucket_arn}/*"
      }
    ]
  })
}

# =============================================================================
# CloudWatch Logs Policy
# =============================================================================
resource "aws_iam_role_policy" "ec2_cloudwatch_logs" {
  name = "${var.environment}-foundry-cloudwatch-logs-policy"
  role = aws_iam_role.ec2_foundry.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateLogGroup"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/foundry/*"
      },
      {
        Sid    = "CreateLogStream"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/foundry/*:*"
      }
    ]
  })
}

# =============================================================================
# Secrets Manager Policy
# =============================================================================
resource "aws_iam_role_policy" "ec2_secrets_manager" {
  name = "${var.environment}-foundry-secrets-policy"
  role = aws_iam_role.ec2_foundry.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetDatabaseSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/foundry/database*"
      }
    ]
  })
}

# =============================================================================
# EC2 SSM Policy (Systems Manager for session manager access)
# =============================================================================
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_foundry.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# =============================================================================
# CloudWatch Agent Policy
# =============================================================================
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent" {
  role       = aws_iam_role.ec2_foundry.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# =============================================================================
# Data Source
# =============================================================================
data "aws_caller_identity" "current" {}
