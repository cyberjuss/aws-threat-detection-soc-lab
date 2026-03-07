# =============================================================================
# S3 Buckets for CloudTrail, AWS Config, and VPC Flow Logs
# =============================================================================
# Each log type has its own bucket. Lifecycle rules expire objects after 90
# days to control storage cost. Bucket names use a random or custom suffix
# so they are globally unique (S3 requirement).
# =============================================================================

# -----------------------------------------------------------------------------
# Data sources: current AWS account and region
# -----------------------------------------------------------------------------
# Used in bucket policies and naming. No credentials needed beyond what the
# provider uses; these are read-only lookups.
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Random suffix for S3 bucket names
# -----------------------------------------------------------------------------
# 4 bytes = 8 hex characters. Combined with project_name to form names like
# soc-lab-cloudtrail-a1b2c3d4. Ignored if var.s3_bucket_suffix is set.
# -----------------------------------------------------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  # Suffix: use variable if set, otherwise random hex from random_id.
  suffix     = var.s3_bucket_suffix != null ? var.s3_bucket_suffix : random_id.bucket_suffix.hex
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# =============================================================================
# CloudTrail S3 bucket
# =============================================================================
# CloudTrail will write log files here. Bucket policy is in cloudtrail.tf.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.project_name}-cloudtrail-${local.suffix}"

  force_destroy = true

  tags = {
    Name = "${var.project_name}-cloudtrail"
  }
}

# Delete objects after 90 days; delete noncurrent versions after 30 days.
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {} # Apply to all objects (required by provider 5.x)

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Versioning is often required or recommended for CloudTrail log integrity.
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access (security best practice for log buckets).
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# AWS Config S3 bucket (only if enable_config is true)
# =============================================================================
# AWS Config delivers configuration snapshots and change deltas here. Bucket
# policy is in config.tf so the Config service can write.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "config" {
  count  = var.enable_config ? 1 : 0
  bucket = "${var.project_name}-config-${local.suffix}"

  force_destroy = true

  tags = {
    Name = "${var.project_name}-config"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {} # Apply to all objects (required by provider 5.x)

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# VPC Flow Logs S3 bucket (only if enable_vpc_flow_logs is true)
# =============================================================================
# VPC Flow Logs are delivered to this bucket by the delivery.logs.amazonaws.com
# service. Bucket policy is in vpc_flow_logs.tf.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs ? 1 : 0
  bucket = "${var.project_name}-vpcflow-${local.suffix}"

  force_destroy = true

  tags = {
    Name = "${var.project_name}-vpcflow"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {} # Apply to all objects (required by provider 5.x)

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
