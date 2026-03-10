# =============================================================================
# CloudTrail Trail and S3 Bucket Policy
# =============================================================================
# CloudTrail records API calls in your account and writes log files to S3.
# The bucket policy below allows the CloudTrail service to perform an ACL
# check and to put objects; conditions restrict access to your account and
# require bucket-owner-full-control to avoid ownership issues.
# =============================================================================

# -----------------------------------------------------------------------------
# S3 bucket policy for CloudTrail
# -----------------------------------------------------------------------------
# AWS requires this policy so cloudtrail.amazonaws.com can write to the
# bucket. Without it, the trail cannot deliver logs. Conditions ensure only
# CloudTrail in your account can write.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudTrail checks bucket ACL before writing (AWS requirement).
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      },
      # CloudTrail writes log files; ACL condition is required by CloudTrail.
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/*"
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

# -----------------------------------------------------------------------------
# CloudTrail trail
# -----------------------------------------------------------------------------
# Single-region trail that logs to the S3 bucket above. include_global_service_
# events captures IAM/STS etc. in the same region; enable_log_file_validation
# enables digest verification. Depends on bucket policy so CloudTrail can
# write immediately after creation.
# -----------------------------------------------------------------------------
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail
  ]

  tags = {
    Name = "${var.project_name}-trail"
  }
}
