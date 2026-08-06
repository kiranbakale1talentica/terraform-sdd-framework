output "dynamodb_table_id" {
  value       = module.database.dynamodb_table_id
  description = "The name/ID of the created DynamoDB table"
}

output "dynamodb_table_arn" {
  value       = module.database.dynamodb_table_arn
  description = "The Amazon Resource Name (ARN) of the created DynamoDB table"
}

output "dynamodb_table_name" {
  value       = module.database.dynamodb_table_name
  description = "The name of the created DynamoDB table"
}
