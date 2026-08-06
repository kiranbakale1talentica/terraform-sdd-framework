output "s3_bucket_id" {
  value       = aws_s3_bucket.main.id
  description = "The name/ID of the created S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "The Amazon Resource Name (ARN) of the created S3 bucket"
}

output "s3_bucket_domain_name" {
  value       = aws_s3_bucket.main.bucket_domain_name
  description = "The bucket domain name of the created S3 bucket"
}

output "s3_bucket_regional_domain_name" {
  value       = aws_s3_bucket.main.bucket_regional_domain_name
  description = "The regional bucket domain name of the created S3 bucket"
}
