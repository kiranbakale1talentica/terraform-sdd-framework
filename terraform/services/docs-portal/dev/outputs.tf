output "cloudfront_url" {
  value       = module.frontend_hosting.cloudfront_url
  description = "HTTPS URL of the CloudFront distribution"
}

output "s3_assets_bucket" {
  value       = module.frontend_hosting.s3_assets_bucket
  description = "Name of the S3 bucket for assets"
}
