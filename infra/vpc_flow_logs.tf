# =============================================================================
# VPC Flow Logs to S3 (Default VPC)
# =============================================================================
# VPC Flow Logs capture accepted/rejected traffic at the network interface
# level. When destination is S3, AWS uses the delivery.logs.amazonaws.com
# service to write to the bucket (no IAM role needed for S3 destination).
# This configuration uses the default VPC in the region.
# =============================================================================

# -----------------------------------------------------------------------------
# Default VPC data source
# -----------------------------------------------------------------------------
# Look up the default VPC in the selected region. If your account has no
# default VPC (e.g. in some newer accounts), set enable_vpc_flow_logs = false
# or create a default VPC first.
# -----------------------------------------------------------------------------
data "aws_vpc" "default" {
  count   = var.enable_vpc_flow_logs ? 1 : 0
  default = true
}

# -----------------------------------------------------------------------------
# VPC Flow Log resource
# -----------------------------------------------------------------------------
# log_destination_type = "s3" and log_destination = bucket ARN send logs
# directly to S3. traffic_type = "ALL" logs both accepted and rejected
# traffic. For CloudWatch Logs you would use an IAM role instead.
# -----------------------------------------------------------------------------
resource "aws_flow_log" "main" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  log_destination      = aws_s3_bucket.vpc_flow_logs[0].arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = data.aws_vpc.default[0].id

  tags = {
    Name = "${var.project_name}-vpc-flow-logs"
  }
}

# -----------------------------------------------------------------------------
# S3 bucket policy for VPC Flow Logs delivery
# -----------------------------------------------------------------------------
# When destination is S3, the delivery.logs.amazonaws.com service writes
# flow log files. This policy allows that service to get bucket ACL and
# put objects; conditions restrict to your account and require
# bucket-owner-full-control.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.vpc_flow_logs[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      },
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.vpc_flow_logs[0].arn}/*"
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
