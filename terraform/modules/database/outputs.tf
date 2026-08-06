output "dynamodb_table_id" {
  value       = aws_dynamodb_table.main.id
  description = "The name/ID of the created DynamoDB table"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.main.arn
  description = "The Amazon Resource Name (ARN) of the created DynamoDB table"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.main.name
  description = "The name of the created DynamoDB table"
}
