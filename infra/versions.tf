# =============================================================================
# Terraform & Provider Requirements
# =============================================================================
# This file defines the minimum Terraform version and required providers.
# Run `terraform init` once to download providers before plan/apply.
# =============================================================================

terraform {
  # Minimum Terraform version; 1.0+ is required for stable HCL and features.
  required_version = ">= 1.0"

  required_providers {
    # AWS provider: used to create and manage all AWS resources (S3, CloudTrail,
    # Config, IAM, VPC Flow Logs, etc.). Version ~> 5.0 allows
    # 5.x patches but not 6.0.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Random provider: generates a random hex suffix for S3 bucket names so
    # bucket names are globally unique across AWS accounts (S3 bucket names
    # must be unique across all of AWS).
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # ---------------------------------------------------------------------------
  # Optional: Remote state backend
  # ---------------------------------------------------------------------------
  # By default Terraform keeps state in a local file (terraform.tfstate).
  # For team use or safety, uncomment the block below and set the bucket name,
  # key, region, and (optionally) a DynamoDB table for state locking.
  # You must create the S3 bucket and DynamoDB table before running terraform init.
  # ---------------------------------------------------------------------------
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "soc-lab/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# -----------------------------------------------------------------------------
# AWS Provider configuration
# -----------------------------------------------------------------------------
# The region is taken from var.aws_region (default: us-east-1). Credentials
# are read from the environment (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY),
# shared credentials file (~/.aws/credentials), or IAM role (e.g. on EC2).
# default_tags apply to all resources created by this provider unless overridden.
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "aws-soc-lab"
      ManagedBy = "terraform"
    }
  }
}
