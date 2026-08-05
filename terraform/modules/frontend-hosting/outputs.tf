output "cloudfront_url" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "HTTPS URL of the CloudFront distribution"
}

output "s3_assets_bucket" {
  value       = aws_s3_bucket.assets.id
  description = "Name of the S3 bucket for assets"
}
