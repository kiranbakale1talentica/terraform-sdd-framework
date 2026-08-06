# Bootstrap Infrastructure for Terraform Remote State & GitHub Actions OIDC
#
# Usage: Run this ONCE manually or via AWS CLI in your AWS account to bootstrap:
#   1. S3 bucket for Terraform state storage + Native State Locking (Terraform v1.10+)
#   2. IAM Role + OIDC Provider for keyless GitHub Actions authentication
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── Variables ───────────────────────────────────────────────────────────────
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for bootstrap resources"
}

variable "project_prefix" {
  type        = string
  default     = "terraform-sdd"
  description = "Prefix used for naming bootstrap resources"
}

variable "github_org_repo" {
  type        = string
  description = "GitHub organization/username and repository name (e.g. org/repo or org/repo:*)"
}

# ─── 1. S3 Bucket for Terraform Remote State & Native Locking ────────────────
resource "aws_s3_bucket" "tf_state" {
  bucket        = "${var.project_prefix}-tfstate-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "${var.project_prefix}-tfstate"
    ManagedBy = "bootstrap"
    Purpose   = "Terraform State Storage and Native S3 Locking"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── 2. GitHub Actions OIDC Authentication ───────────────────────────────────
data "aws_caller_identity" "current" {}

# Create OIDC Provider if it doesn't already exist in the AWS Account
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${var.project_prefix}-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "${var.project_prefix}-github-actions-role"
    ManagedBy = "bootstrap"
  }
}

# Attach Policy granting permissions needed for Terraform State & Deployments
resource "aws_iam_role_policy" "github_actions_permissions" {
  name = "TerraformExecutionPolicy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ── Remote state: read/write S3 state bucket ─────────────────────────
      {
        Sid    = "TerraformStateBucket"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.tf_state.arn,
          "${aws_s3_bucket.tf_state.arn}/*"
        ]
      },
      # ── S3: provision docs-portal assets & log buckets ───────────────────
      {
        Sid    = "S3BucketProvisioning"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl",
          "s3:GetBucketCORS",
          "s3:PutBucketCORS",
          "s3:GetBucketLogging",
          "s3:PutBucketLogging",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:PutBucketWebsite",
          "s3:DeleteBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:GetAccelerateConfiguration",
          "s3:PutAccelerateConfiguration",
          "s3:GetBucketRequestPayment",
          "s3:PutBucketRequestPayment",
          "s3:GetReplicationConfiguration",
          "s3:PutReplicationConfiguration",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging"
        ]
        Resource = ["*"]
      },
      # ── CloudFront: provision CDN distribution ────────────────────────────
      {
        Sid    = "CloudFrontProvisioning"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateDistribution",
          "cloudfront:UpdateDistribution",
          "cloudfront:DeleteDistribution",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListDistributions",
          "cloudfront:CreateOriginAccessControl",
          "cloudfront:UpdateOriginAccessControl",
          "cloudfront:DeleteOriginAccessControl",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:GetOriginAccessControlConfig",
          "cloudfront:ListOriginAccessControls",
          "cloudfront:CreateCloudFrontOriginAccessIdentity",
          "cloudfront:UpdateCloudFrontOriginAccessIdentity",
          "cloudfront:DeleteCloudFrontOriginAccessIdentity",
          "cloudfront:GetCloudFrontOriginAccessIdentity",
          "cloudfront:GetCloudFrontOriginAccessIdentityConfig",
          "cloudfront:TagResource",
          "cloudfront:UntagResource",
          "cloudfront:ListTagsForResource",
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = ["*"]
      },
      # ── ACM: provision TLS certificates ──────────────────────────────────
      {
        Sid    = "ACMProvisioning"
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DescribeCertificate",
          "acm:DeleteCertificate",
          "acm:ListCertificates",
          "acm:AddTagsToCertificate",
          "acm:ListTagsForCertificate",
          "acm:GetCertificate"
        ]
        Resource = ["*"]
      },
      # ── Route 53: DNS zone lookup & record management ───────────────────
      {
        Sid    = "Route53Permissions"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:ListTagsForResource",
          "route53:ListTagsForResources",
          "route53:GetChange"
        ]
        Resource = ["*"]
      },
      # ── STS: verify caller identity after assume (used by configure-aws-credentials) ─
      {
        Sid      = "STSGetCallerIdentity"
        Effect   = "Allow"
        Action   = ["sts:GetCallerIdentity"]
        Resource = ["*"]
      }
    ]
  })
}

# ─── Outputs ─────────────────────────────────────────────────────────────────
output "s3_bucket_name" {
  value       = aws_s3_bucket.tf_state.id
  description = "Use this in backend.tf as bucket"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Use this in .github/workflows/*.yml as OIDC_ROLE_ARN"
}
