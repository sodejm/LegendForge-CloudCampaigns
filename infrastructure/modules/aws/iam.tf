# =============================================================================
# AWS IAM — EC2 Instance Role, Secrets Manager Access, CloudWatch Logs
# =============================================================================

# ===== IAM Role for EC2 Instance =====
resource "aws_iam_role" "ec2_instance_role" {
  name               = "${local.name_prefix}-ec2-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# ===== Instance Profile =====
resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

# ===== IAM Policy: Secrets Manager Read-Only Access =====
resource "aws_iam_role_policy" "secrets_manager_read" {
  name   = "${local.name_prefix}-secrets-manager-read-policy"
  role   = aws_iam_role.ec2_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = local.project
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = local.project
          }
        }
      }
    ]
  })
}

# ===== IAM Policy: CloudWatch Logs Write Access =====
resource "aws_iam_role_policy" "cloudwatch_logs_write" {
  name   = "${local.name_prefix}-cloudwatch-logs-write-policy"
  role   = aws_iam_role.ec2_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:${local.region}:*:log-group:/aws/ec2/${local.name_prefix}*"
      }
    ]
  })
}

# ===== IAM Policy: Systems Manager Session Manager Access =====
# Allows using AWS Systems Manager to connect to the instance without SSH keys
resource "aws_iam_role_policy_attachment" "ssm_session_manager" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ===== IAM Policy: ECS-relevant permissions (for future Container Insights) =====
resource "aws_iam_role_policy" "cloudwatch_container_insights" {
  name   = "${local.name_prefix}-container-insights-policy"
  role   = aws_iam_role.ec2_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}
