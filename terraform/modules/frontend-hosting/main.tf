locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}

# ------------------------------------------------------------------------------
# S3 Buckets
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "assets" {
  # checkov:skip=CKV_AWS_145: KMS encryption is not required; default SSE-S3 is sufficient and keeps costs low.
  # checkov:skip=CKV_AWS_144: Cross-region replication is unnecessary for this simple site.
  # checkov:skip=CKV2_AWS_62: Event notifications not required.
  # checkov:skip=CKV2_AWS_61: Lifecycle configuration not required for assets.
  bucket = "${local.name_prefix}-assets"
  tags   = local.common_tags
}

resource "aws_s3_bucket" "logs" {
  # checkov:skip=CKV_AWS_145: KMS encryption is not required.
  # checkov:skip=CKV_AWS_144: Cross-region replication is unnecessary.
  # checkov:skip=CKV2_AWS_62: Event notifications not required.
  # tfsec:ignore:aws-s3-enable-bucket-logging
  # tfsec:ignore:aws-s3-encryption-customer-key
  bucket = "${local.name_prefix}-logs"
  tags   = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets_sse" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_sse" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "assets_logging" {
  bucket        = aws_s3_bucket.assets.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

resource "aws_s3_bucket_versioning" "assets_versioning" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "auto-delete-old-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets_pab" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "assets_ownership" {
  bucket = aws_s3_bucket.assets.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_pab" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs_ownership" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ------------------------------------------------------------------------------
# Origin Access Control (OAC) and S3 Bucket Policy
# ------------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for ${local.name_prefix}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "assets_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "assets_policy" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets_policy.json
}

data "aws_iam_policy_document" "logs_policy" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/cf-logs/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "logs_policy" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_policy.json
}

# ------------------------------------------------------------------------------
# ACM and Route53
# ------------------------------------------------------------------------------

data "aws_route53_zone" "this" {
  name = var.domain_name
}

resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ------------------------------------------------------------------------------
# CloudFront Distribution
# ------------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "cdn" {
  # checkov:skip=CKV_AWS_68: WAF is explicitly not required by the user spec.
  # checkov:skip=CKV2_AWS_47: WAF is explicitly not required.
  # checkov:skip=CKV_AWS_310: Origin failover not required for simple site.
  # checkov:skip=CKV_AWS_374: Geo restriction not required.
  # checkov:skip=CKV2_AWS_32: Managed SecurityHeadersPolicy is attached in default_cache_behavior.
  # tfsec:ignore:aws-cloudfront-enable-waf

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = "PriceClass_100"
  tags                = local.common_tags

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # AWS Managed SecurityHeadersPolicy
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_regional_domain_name
    prefix          = "cf-logs/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.this.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "cdn_alias" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
