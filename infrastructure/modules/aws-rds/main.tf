# =============================================================================
# infrastructure/modules/aws-rds/main.tf
# =============================================================================
# LegendForge AWS Rds module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# =============================================================================
# DB Subnet Group
# =============================================================================
resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.environment}-"
  description = "DB subnet group for ${var.environment}"
  subnet_ids  = var.database_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-db-subnet-group"
    }
  )
}

# =============================================================================
# RDS Enhanced Monitoring Role
# =============================================================================
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# =============================================================================
# RDS Instance (PostgreSQL)
# =============================================================================
resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-foundry-db"
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage  = var.allocated_storage
  storage_type       = "gp3"
  storage_encrypted  = true
  iops               = var.iops
  storage_throughput = var.storage_throughput

  # Credentials (from Secrets Manager)
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password

  # HA & Backup
  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]

  backup_retention_period   = var.backup_retention_days
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.environment}-foundry-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Monitoring
  enabled_cloudwatch_logs_exports       = ["postgresql"]
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  enable_iam_database_authentication    = true

  # Parameters
  parameter_group_name = aws_db_parameter_group.main.name

  # Foundry-specific tuning
  deletion_protection = true
  publicly_accessible = false

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-foundry-db"
    }
  )

  depends_on = [aws_iam_role_policy_attachment.rds_monitoring]
}

# =============================================================================
# DB Parameter Group (tuned for LegendForge)
# =============================================================================
resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.environment}-"
  family      = "postgres${split(".", var.postgres_version)[0]}"
  description = "Parameter group for ${var.environment} LegendForge database with multi-system support."

  # Connection pooling and performance tuning
  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/32768}"
  }

  parameter {
    name  = "effective_cache_size"
    value = "{DBInstanceClassMemory/4096}"
  }

  parameter {
    name  = "maintenance_work_mem"
    value = "{DBInstanceClassMemory/16}"
  }

  parameter {
    name  = "checkpoint_completion_target"
    value = "0.9"
  }

  parameter {
    name  = "wal_buffers"
    value = "16384"
  }

  parameter {
    name  = "default_statistics_target"
    value = "100"
  }

  parameter {
    name  = "random_page_cost"
    value = "1.1"
  }

  parameter {
    name  = "effective_io_concurrency"
    value = "200"
  }

  parameter {
    name  = "work_mem"
    value = "{DBInstanceClassMemory/131072}"
  }

  parameter {
    name  = "min_wal_size"
    value = "1024"
  }

  parameter {
    name  = "max_wal_size"
    value = "4096"
  }

  # Foundry-specific settings
  parameter {
    name  = "log_statement"
    value = "mod"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-db-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# RDS Cluster (optional - for even higher availability)
# Uncomment if you want Aurora PostgreSQL instead of standalone RDS
# =============================================================================
# resource "aws_rds_cluster" "main" {
#   cluster_identifier              = "${var.environment}-foundry-cluster"
#   engine                          = "aurora-postgresql"
#   engine_version                  = var.postgres_version
#   database_name                   = var.database_name
#   master_username                 = var.database_username
#   master_password                 = var.database_password
#   db_subnet_group_name            = aws_db_subnet_group.main.name
#   db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
#   vpc_security_group_ids          = [var.rds_security_group_id]
#   storage_encrypted               = true
#   backup_retention_period         = var.backup_retention_days
#   preferred_backup_window         = "03:00-04:00"
#   preferred_maintenance_window    = "mon:04:00-mon:05:00"
#   enabled_cloudwatch_logs_exports = ["postgresql"]
#   deletion_protection             = true
#   skip_final_snapshot             = false
#   final_snapshot_identifier       = "${var.environment}-foundry-cluster-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.environment}-foundry-cluster"
#     }
#   )
# }
