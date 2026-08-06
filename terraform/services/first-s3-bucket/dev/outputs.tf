output "s3_bucket_id" {
  value       = module.storage.s3_bucket_id
  description = "The name/ID of the created S3 bucket"
}

output "s3_bucket_arn" {
  value       = module.storage.s3_bucket_arn
  description = "The Amazon Resource Name (ARN) of the created S3 bucket"
}

output "s3_bucket_domain_name" {
  value       = module.storage.s3_bucket_domain_name
  description = "The domain name of the created S3 bucket"
}

output "s3_bucket_regional_domain_name" {
  value       = module.storage.s3_bucket_regional_domain_name
  description = "The regional domain name of the created S3 bucket"
}
