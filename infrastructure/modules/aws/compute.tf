# =============================================================================
# AWS Compute — EC2 Instance, Volume Attachment, User Data
# =============================================================================

# ===== EC2 Instance =====
resource "aws_instance" "foundry" {
  count                = var.compute_enabled ? 1 : 0
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = local.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2.name
  subnet_id            = aws_subnet.public[0].id
  security_groups      = [aws_security_group.compute.id]

  # IMDSv2 enforcement (recommended security best practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Root volume: gp3 encrypted
  root_block_device {
    volume_type           = local.root_volume_type
    volume_size           = local.root_volume_size
    delete_on_termination = true
    encrypted             = true
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-root-volume"
    })
  }

  # SSH public key (if break-glass is enabled)
  key_name = var.admin_ssh_cidr != null && var.admin_ssh_public_key != "" ? aws_key_pair.admin[0].key_name : null

  # User data: Pass to foundry-app module to generate cloud-init script
  user_data = module.foundry_app.user_data

  # CloudWatch monitoring
  monitoring = var.enable_monitoring

  # Associate public IP
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-foundry-instance"
    Type = "Compute"
  })

  depends_on = [
    aws_iam_role_policy.secrets_manager_read,
    aws_iam_role_policy.cloudwatch_logs_write
  ]
}

# ===== SSH Key Pair (Break-glass only) =====
resource "aws_key_pair" "admin" {
  count      = var.admin_ssh_cidr != null && var.admin_ssh_public_key != "" ? 1 : 0
  key_name   = "${local.name_prefix}-admin-key"
  public_key = var.admin_ssh_public_key

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-admin-key"
  })
}

# ===== EBS Volume Attachment =====
resource "aws_volume_attachment" "foundry_data" {
  count           = var.compute_enabled ? 1 : 0
  device_name     = "/dev/sdf"
  volume_id       = aws_ebs_volume.foundry_data[0].id
  instance_id     = aws_instance.foundry[0].id
  force_detach    = false
}

# ===== Foundry App Module (Provider-agnostic cloud-init generator) =====
# This module generates the cloud-init user data script for Foundry VTT
module "foundry_app" {
  source = "../../modules/foundry-app"

  foundry_hostname         = var.foundry_hostname
  data_device              = "/dev/disk/by-id/nvme-*-volume-foundry-data"  # AWS EBS volume ID reference
  data_mount_path          = var.data_mount_path
  data_volume_fs_label     = var.data_volume_fs_label
  foundry_image            = var.foundry_image
  cloudflared_image        = var.cloudflared_image
  timezone                 = var.timezone
  foundry_username         = var.foundry_username
  foundry_password         = var.foundry_password
  foundry_release_url      = var.foundry_release_url
  foundry_license_key      = var.foundry_license_key
  foundry_admin_key        = var.foundry_admin_key
  cloudflare_tunnel_token  = var.cloudflare_tunnel_token
}

# ===== CloudWatch Detailed Monitoring (if enabled) =====
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_monitoring && var.compute_enabled ? 1 : 0
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Alert when CPU exceeds ${var.cpu_alarm_threshold}%"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.foundry[0].id
  }

  tags = local.common_tags
}

# ===== CloudWatch Log Group for EC2 Logs =====
resource "aws_cloudwatch_log_group" "ec2_logs" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/aws/ec2/${local.name_prefix}/system"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-logs"
  })
}

# ===== CloudWatch Dashboard =====
resource "aws_cloudwatch_dashboard" "foundry" {
  count          = var.enable_monitoring && var.compute_enabled ? 1 : 0
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            [".", "NetworkIn", { stat = "Sum" }],
            [".", "NetworkOut", { stat = "Sum" }],
          ]
          period = 300
          stat   = "Average"
          region = local.region
          title  = "EC2 Instance Metrics"
        }
      }
    ]
  })
}
