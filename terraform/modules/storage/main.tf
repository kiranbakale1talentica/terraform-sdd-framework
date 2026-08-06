data "aws_caller_identity" "current" {}

locals {
  bucket_name = lower("${var.project_prefix}-${var.bucket_name_suffix}-${data.aws_caller_identity.current.account_id}")

  default_tags = {
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "storage"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  merged_tags = merge(local.default_tags, var.tags)
}

resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name
  force_destroy = var.environment == "dev" ? true : false

  tags = merge(local.merged_tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  depends_on = [aws_s3_bucket_versioning.main]
  bucket     = aws_s3_bucket.main.id

  rule {
    id     = "transition-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_transition {
      noncurrent_days = var.noncurrent_version_transition_days
      storage_class   = "STANDARD_IA"
    }
  }
}
