# =============================================================================
# AWS Storage — EBS Volumes, Snapshots
# =============================================================================

# ===== EBS Volume for Foundry Persistent Data =====
resource "aws_ebs_volume" "foundry_data" {
  count             = var.compute_enabled ? 1 : 0
  availability_zone = local.availability_zones[0]
  size              = var.data_volume_size_gb
  type              = "gp3"
  iops              = 3000
  throughput        = 125
  encrypted         = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-foundry-data-volume"
  })
}

# ===== Backup Schedule for EBS Volume =====
resource "aws_backup_vault" "foundry" {
  count           = var.enable_volume_snapshots ? 1 : 0
  name            = "${local.name_prefix}-backup-vault"
  recovery_points = 30

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backup-vault"
  })
}

# ===== Backup Plan for Daily Snapshots =====
resource "aws_backup_plan" "foundry_daily" {
  count = var.enable_volume_snapshots ? 1 : 0
  name  = "${local.name_prefix}-daily-snapshot-plan"

  rule {
    rule_name                = "daily-snapshot"
    target_backup_vault_name = aws_backup_vault.foundry[0].name
    schedule                 = "cron(0 2 ? * * *)" # 2 AM UTC daily
    start_window             = 60
    completion_window        = 120
    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }
    recovery_point_tags = merge(local.common_tags, {
      SnapshotType = "DailyBackup"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backup-plan"
  })
}

# ===== Backup Resource Assignment =====
resource "aws_backup_resource_assignment" "foundry_volume" {
  count               = var.enable_volume_snapshots && var.compute_enabled ? 1 : 0
  name                = "${local.name_prefix}-volume-backup-assignment"
  backup_plan_id      = aws_backup_plan.foundry_daily[0].id
  iam_role_arn        = aws_iam_role.backup[0].arn
  resources           = [aws_ebs_volume.foundry_data[0].arn]
  selection_tag_key   = "Backup"
  selection_tag_type  = "STRINGEQUALS"
  selection_tag_value = "true"

  depends_on = [aws_iam_role_policy.backup]
}

# ===== IAM Role for AWS Backup =====
resource "aws_iam_role" "backup" {
  count = var.enable_volume_snapshots ? 1 : 0
  name  = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# ===== IAM Policy for AWS Backup =====
resource "aws_iam_role_policy" "backup" {
  count = var.enable_volume_snapshots ? 1 : 0
  name  = "${local.name_prefix}-backup-policy"
  role  = aws_iam_role.backup[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# ===== EBS Snapshot Resource (manual snapshot capability) =====
resource "aws_ebs_snapshot" "foundry_manual" {
  count                 = var.compute_enabled ? 1 : 0
  volume_id             = aws_ebs_volume.foundry_data[0].id
  description           = "Manual snapshot of Foundry data volume"
  copy_on_region_change = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-foundry-data-snapshot"
  })
}
