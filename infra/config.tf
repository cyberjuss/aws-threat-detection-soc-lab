# =============================================================================
# AWS Config: Recorder and Delivery Channel to S3
# =============================================================================
# AWS Config records configuration changes and delivers snapshots/deltas to S3.
# The recorder runs in the account; the delivery channel points to our Config
# bucket. An IAM role allows Config to write to S3; the bucket policy allows
# the Config service to write (both are required by AWS).
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration recorder
# -----------------------------------------------------------------------------
# Records configuration for all supported resource types in the region,
# including global resources (e.g. IAM). Must be started after the delivery
# channel exists (see aws_config_configuration_recorder_status below).
# -----------------------------------------------------------------------------
resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config ? 1 : 0

  name     = "${var.project_name}-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# -----------------------------------------------------------------------------
# Delivery channel
# -----------------------------------------------------------------------------
# Tells Config where to deliver snapshot and incremental files (our S3 bucket).
# The s3_key_prefix is a folder prefix inside the bucket.
# -----------------------------------------------------------------------------
resource "aws_config_delivery_channel" "main" {
  count = var.enable_config ? 1 : 0

  name           = "${var.project_name}-config-delivery"
  s3_bucket_name = aws_s3_bucket.config[0].id
  s3_key_prefix  = "config"

  depends_on = [aws_config_configuration_recorder.main]
}

# -----------------------------------------------------------------------------
# Recorder status: set to enabled
# -----------------------------------------------------------------------------
# The recorder is created in a stopped state. This resource turns it on so
# Config actually starts recording. Must run after delivery channel is set.
# -----------------------------------------------------------------------------
resource "aws_config_configuration_recorder_status" "main" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# -----------------------------------------------------------------------------
# IAM role for AWS Config
# -----------------------------------------------------------------------------
# Config assumes this role to write to S3 and to describe resources. The
# managed policy ConfigRole grants permissions to describe resource types.
# -----------------------------------------------------------------------------
resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0

  name = "${var.project_name}-config-delivery-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Inline policy: allow Config to put objects and set ACL on the Config bucket.
resource "aws_iam_role_policy" "config" {
  count = var.enable_config ? 1 : 0

  name = "${var.project_name}-config-s3"
  role = aws_iam_role.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.config[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config[0].arn
      }
    ]
  })
}

# Inline policy: Config recorder needs these to describe resources and deliver snapshots.
# (Replaces managed policy ConfigRole which may not exist in all partitions/accounts.)
resource "aws_iam_role_policy" "config_recorder" {
  count = var.enable_config ? 1 : 0

  name = "${var.project_name}-config-recorder"
  role = aws_iam_role.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["config:Put*", "config:Get*", "config:Describe*", "config:List*", "config:Deliver*"]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# S3 bucket policy for AWS Config
# -----------------------------------------------------------------------------
# Config requires the bucket to allow config.amazonaws.com to get ACL, list
# bucket, and put objects (with bucket-owner-full-control). Without this,
# delivery will fail.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "config" {
  count = var.enable_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.config[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      },
      {
        Sid       = "AWSConfigBucketExistenceCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.config[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      },
      {
        Sid       = "AWSConfigBucketDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.config[0].arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          StringLike = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
