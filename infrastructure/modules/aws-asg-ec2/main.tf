# =============================================================================
# infrastructure/modules/aws-asg-ec2/main.tf
# =============================================================================
# LegendForge AWS Asg Ec2 module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# =============================================================================
# Launch Template
# =============================================================================
resource "aws_launch_template" "foundry" {
  name_prefix   = "${var.environment}-foundry-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  # IAM instance profile for S3, CloudWatch, Secrets Manager access
  iam_instance_profile {
    arn = var.instance_profile_arn
  }

  # VPC and security
  vpc_security_group_ids = [var.asg_security_group_id]

  # EBS root volume configuration
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  # EBS data volume for persistent LegendForge platform data
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size           = var.data_volume_size
      volume_type           = "gp3"
      delete_on_termination = false
      encrypted             = true
    }
  }

  # CloudWatch monitoring
  monitoring {
    enabled = true
  }

  # User data with cloud-init
  user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    environment              = var.environment
    aws_region               = var.aws_region
    foundry_hostname         = var.foundry_hostname
    foundry_image            = var.foundry_image
    cloudflared_image        = var.cloudflared_image
    cloudflare_tunnel_token  = var.cloudflare_tunnel_token
    foundry_license_key      = var.foundry_license_key
    foundry_admin_key        = var.foundry_admin_key
    db_host                  = var.db_host
    db_port                  = var.db_port
    db_name                  = var.db_name
    db_username              = var.db_username
    db_password              = var.db_password
    foundry_data_bucket      = var.foundry_data_bucket
    cloudwatch_log_group     = var.cloudwatch_log_group
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name = "${var.environment}-foundry-instance"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      var.tags,
      {
        Name = "${var.environment}-foundry-volume"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Auto Scaling Group
# =============================================================================
resource "aws_autoscaling_group" "foundry" {
  name                = "${var.environment}-foundry-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.foundry.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-foundry-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Scaling Policies (CPU-based)
# =============================================================================
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.environment}-foundry-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.foundry.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.environment}-foundry-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.foundry.name
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${var.environment}-foundry-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Scale up when CPU > 70%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.foundry.name
  }
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_low" {
  alarm_name          = "${var.environment}-foundry-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "Scale down when CPU < 30%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.foundry.name
  }
}

# =============================================================================
# Data Sources
# =============================================================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
